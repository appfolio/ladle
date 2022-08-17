require 'test_helper'

class SecurityTest < AppfolioUnitTestCase
  def test_cve_2022_32224_safe
    assert(Rails.application.config.active_record.yaml_column_permitted_classes == nil || Rails.application.config.active_record.yaml_column_permitted_classes.empty?, "CVE-2022-32224 yaml_unsafe_load is unsafe")
    assert(Rails.application.config.active_record.use_yaml_unsafe_load == false || Rails.application.config.active_record.use_yaml_unsafe_load == nil, "CVE-2022-32224 yaml_unsafe_load is unsafe")
  end
end
