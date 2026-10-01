defmodule PTAX.HolidaysTest do
  use ExUnit.Case, async: true

  alias PTAX.Holidays

  describe "holiday?/1" do
    test "returns true for a national holiday listed by ANBIMA" do
      assert Holidays.holiday?(~D[2026-04-21])
    end

    test "returns true for a movable holiday listed by ANBIMA" do
      assert Holidays.holiday?(~D[2026-06-04])
    end

    test "returns false for a business day" do
      refute Holidays.holiday?(~D[2026-04-22])
    end

    test "returns false for a date outside the ANBIMA range" do
      refute Holidays.holiday?(~D[2000-12-25])
    end
  end
end
