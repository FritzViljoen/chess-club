require_relative "../cop_case"

class NoCallbacksTest < CopCase
  polices RuboCop::Cop::Model::NoCallbacks
  on_path "app/models/person.rb"

  test "every persistence callback is an offense" do
    assert_model_offense "before_save :normalize_email"
    assert_model_offense "after_save :reindex"
    assert_model_offense "around_save :instrument"
    assert_model_offense "before_create :assign_number"
    assert_model_offense "after_create :notify"
    assert_model_offense "around_create :instrument"
    assert_model_offense "before_update :stamp"
    assert_model_offense "after_update :notify"
    assert_model_offense "around_update :instrument"
    assert_model_offense "before_destroy :check_events"
    assert_model_offense "after_destroy :cleanup"
    assert_model_offense "around_destroy :instrument"
  end

  test "validation callbacks are offenses" do
    assert_model_offense "before_validation :normalize_email"
    assert_model_offense "after_validation :log"
  end

  test "commit and rollback callbacks are offenses" do
    assert_model_offense "before_commit :normalize_email"
    assert_model_offense "after_commit :notify"
    assert_model_offense "after_rollback :log"
    assert_model_offense "after_create_commit :notify"
    assert_model_offense "after_update_commit :notify"
    assert_model_offense "after_destroy_commit :notify"
    assert_model_offense "after_save_commit :notify"
  end

  test "lifecycle callbacks that are not writes are offenses" do
    assert_model_offense "after_initialize :set_defaults"
    assert_model_offense "after_find :touch_seen_at"
    assert_model_offense "after_touch :reindex"
  end

  test "the block form is an offense" do
    assert_model_offense <<~RUBY
      after_create_commit { Mailer.welcome(self).deliver_later }
    RUBY
  end

  test "options and conditions do not excuse a callback" do
    assert_model_offense "before_save :normalize_email, if: :email_changed?"
    assert_model_offense "before_save :normalize_email, on: :create"
  end

  test "each callback is reported separately" do
    assert_model_offense <<~RUBY, count: 2
      before_save :normalize_email
      after_create :notify
    RUBY
  end

  test "the message names the callback it found" do
    offense = offenses(model("before_save :normalize_email")).sole

    assert_includes offense.message, "before_save"
  end

  test "a model with no callbacks is accepted" do
    assert_model_clean <<~RUBY
      belongs_to :group
      has_many :events, dependent: :destroy

      validates :email, presence: true

      def normalize_email
        self.email = email.strip.downcase
      end
    RUBY
  end

  test "a same-named method on another receiver is left alone" do
    assert_model_clean "observer.after_save :notify"
    assert_model_clean "Rails.application.config.after_initialize { boot }"
  end

  test "defining a method with a callback's name is left alone" do
    assert_model_clean <<~RUBY
      def after_save
        reindex
      end
    RUBY
  end

  private
    def assert_model_offense(body, count: 1)
      assert_offenses model(body), count
    end

    def assert_model_clean(body)
      assert_offenses model(body), 0
    end

    def model(body)
      <<~RUBY
        class Person < ApplicationRecord
        #{body.indent(2)}
        end
      RUBY
    end
end
