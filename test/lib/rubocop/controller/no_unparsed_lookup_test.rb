require_relative "../cop_case"

class NoUnparsedLookupTest < CopCase
  polices RuboCop::Cop::Controller::NoUnparsedLookup
  on_path "app/controllers/rounds_controller.rb"

  test "a raw parameter reaching a finder is an offense" do
    assert_source_offense "Person.find(params[:id])\n"
    assert_source_offense "Person.find_by(id: params[:id])\n"
    assert_source_offense "Person.find_by!(id: params[:id])\n"
    assert_source_offense "Person.exists?(id: params[:id])\n"
  end

  test "a raw parameter reaching a query is an offense" do
    assert_source_offense "Contest.where(person_id: params[:person_id])\n"
    assert_source_offense "Contest.where(\"person_id = ?\", params[:person_id])\n"
  end

  test "a raw parameter reaching a writer is an offense" do
    assert_source_offense "Person.new(params[:person])\n"
    assert_source_offense "Person.create(name: params[:name])\n"
    assert_source_offense "Person.create!(name: params[:name])\n"
    assert_source_offense "person.update(name: params[:name])\n"
    assert_source_offense "person.update!(name: params[:name])\n"
    assert_source_offense "Person.find_or_create_by(email: params[:email])\n"
    assert_source_offense "Person.find_or_initialize_by(email: params[:email])\n"
  end

  test "params nested inside the argument is still a raw parameter" do
    assert_source_offense "Person.find(params.require(:person)[:id])\n"
    assert_source_offense "Person.where(id: [ params[:id] ])\n"
    assert_source_offense "Person.find(params[:person][:id])\n"
  end

  test "a parsed parameter is what the cop is asking for" do
    assert_source_clean "Person.find(integer_param!(:id))\n"
    assert_source_clean "Person.find_by(id: integer_param!(:id))\n"
    assert_source_clean "Contest.where(person_id: integer_param!(:person_id))\n"
    assert_source_clean "Person.new(name: text_param(:name))\n"
  end

  test "a value that never came from the request is left alone" do
    assert_source_clean "Person.find(id)\n"
    assert_source_clean "Person.where(joined_on: CUTOVER)\n"
    assert_source_clean "Person.new\n"
    assert_source_clean "Person.order(:surname)\n"
  end

  test "a receiverless call of the same name is not a lookup" do
    assert_source_clean "find(params[:id])\n"
  end

  test "a helper that hands back params is params" do
    assert_source_offense "Person.find(person_params[:id])\n"
    assert_source_offense "Person.create(contest_params)\n"
    assert_source_offense "Person.find_or_create_by!(email: signup_params[:email])\n"
  end

  test "the seam parsers are the way out, not another way in" do
    assert_source_clean "Person.find(integer_param!(:id))\n"
    assert_source_clean "Person.find_by(name: text_param(:q))\n"
  end
end
