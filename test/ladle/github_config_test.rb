require 'test_helper'

class GithubConfigTest < ActiveSupport::TestCase

  test "organization_permitted?" do
    config = GithubConfig.new(application_id:                   'app_id',
                              application_secret:               "application_secret",
                              restrict_access_to_organizations: ["duh"])

    assert config.organization_permitted?(["notpermitted", "duh"])

    config = GithubConfig.new(application_id:                   'app_id',
                              application_secret:               "application_secret",
                              restrict_access_to_organizations: ["duh"])

    assert config.organization_permitted?(["duh"])

    config = GithubConfig.new(application_id:                   'app_id',
                              application_secret:               "application_secret",
                              restrict_access_to_organizations: ["duh"])

    refute config.organization_permitted?(["bleh?"])

    config = GithubConfig.new(application_id:                   'app_id',
                              application_secret:               "application_secret")

    assert config.organization_permitted?(["bleh?"])
  end
end
