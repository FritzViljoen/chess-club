require "test_helper"

class LocalZoneTest < ActiveSupport::TestCase
  test "names the zone the application reads times in" do
    assert_equal Rails.configuration.x.local_zone, LocalZone::NAME
  end

  test "answers with a zone, not a string" do
    assert_kind_of ActiveSupport::TimeZone, LocalZone.zone
    assert_equal LocalZone::NAME, LocalZone.zone.name
  end

  test "is not the ambient zone" do
    assert_not_equal Time.zone.name, LocalZone::NAME,
      "expected the application to name its zone rather than inherit the process one"
  end
end
