<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Development](#development)
  - [Running Locally](#running-locally)
  - [Testing application against Github repositories](#testing-application-against-github-repositories)
  - [Testing PR handling against local repositories](#testing-pr-handling-against-local-repositories)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Development

Ladle uses the Github API for authenticating users and interacting with repositories. These uses introduce some intricacies when running the application locally as described in the following sections.

## Running Locally

The only form of authentication is through the Github API. This poses some challenges to running the application locally.

Running the application with the ENV `MOCK_OMNIAUTH=1` ENV stubs out the Github authentication locally. See the [config/initializers/mock_omni_auth.rb](config/initializers/mock_omni_auth.rb) initializer for details.

## Testing application against Github repositories

You can test the application against a remote repository on Github using the following steps:

1. Overwrite the `github_application` credentials in [config/github.yml](config/github.yml).
2. Start the server locally without [mocking](#running-locally): `rails s`.
3. Create `User` and `Repository` records per [Observing Repositories](/README.md#observing-repositories).
4. Create stewards.yml files and pull requests in the remote repository.

## Testing PR handling against local repositories

You can test the handling of PRs using a local repository on the file system using `Ladle::LocalRepositoryClient`:

1. Setup a local repository with scenarios you would like to test.
2. Create a `Ladle::LocalRepositoryClient` and run it through `Ladle::PullHandler`.
3. See [bin/local_test](bin/local_test) for an example.
