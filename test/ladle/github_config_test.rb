require 'test_helper'

class GithubConfigTest < ActiveSupport::TestCase

  test 'organization_permitted?' do
    config = GithubConfig.new(application_id:                   'app_id',
                              application_secret:               'application_secret',
                              restrict_access_to_organizations: ['duh', 'somethingelse'])

    assert config.organization_permitted?(['notpermitted', 'duh'])

    config = GithubConfig.new(application_id:                   'app_id',
                              application_secret:               'application_secret',
                              restrict_access_to_organizations: ['duh', 'somethingelse'])

    assert config.organization_permitted?(['duh'])

    config = GithubConfig.new(application_id:                   'app_id',
                              application_secret:               'application_secret',
                              restrict_access_to_organizations: ['duh'])

    refute config.organization_permitted?(['bleh?'])

    config = GithubConfig.new(application_id:     'app_id',
                              application_secret: 'application_secret')

    assert config.organization_permitted?(['bleh?'])
  end

  test 'from_values' do
    config = GithubConfig.from_values({
                                        'github_application'               => {
                                          'application_id'     => 'app_id',
                                          'application_secret' => 'application_secret',
                                        },
                                        'restrict_access_to_organizations' => 'duh,somethingelse'
                                      })

    assert_equal 'app_id', config.application_id
    assert_equal 'application_secret', config.application_secret
    assert_equal ['duh', 'somethingelse'], config.instance_variable_get(:@restrict_access_to_organizations)

    config = GithubConfig.from_values({
                                        'github_application'               => {
                                          'application_id'     => 'app_id',
                                          'application_secret' => 'application_secret',
                                        },
                                        'restrict_access_to_organizations' => 'duh'
                                      })

    assert_equal ['duh'], config.instance_variable_get(:@restrict_access_to_organizations)

    config = GithubConfig.from_values({
                                        'github_application'               => {
                                          'application_id'     => 'app_id',
                                          'application_secret' => 'application_secret',
                                        },
                                        'restrict_access_to_organizations' => ''
                                      })

    assert_equal [], config.instance_variable_get(:@restrict_access_to_organizations)
  end
end
