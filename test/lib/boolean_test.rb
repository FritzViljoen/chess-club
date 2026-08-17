require "test_helper"

class BooleanTest < ActiveSupport::TestCase
  test "true and false are the only values of the type" do
    assert_kind_of Boolean, true
    assert_kind_of Boolean, false
  end

  test "nothing else is, however truthy it looks" do
    [ nil, 0, 1, "true", "", [] ].each do |value|
      assert_not_kind_of Boolean, value, "#{value.inspect} is not a boolean"
    end
  end
end
