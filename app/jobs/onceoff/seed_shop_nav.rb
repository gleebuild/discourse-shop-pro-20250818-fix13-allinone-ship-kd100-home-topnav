
# frozen_string_literal: true

module ::Jobs
  class SeedShopNav < ::Jobs::Onceoff
    def execute_onceoff(_args)
      if defined?(::DiscourseShopPro::NavSeeder)
        ::DiscourseShopPro::NavSeeder.ensure!
      end
    end
  end
end
