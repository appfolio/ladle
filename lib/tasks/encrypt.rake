# frozen_string_literal: true

namespace :encrypt do
  desc "Migrate user info to new encryption format"
  task :user => :environment do
    updated_count = 0
    error_count = 0

    ActiveRecord::Base.transaction do
      User.find_each do |user|
        user.token = user.token_old

        if user.save
          updated_count += 1
        else
          puts "** Error while updating ID: #{user.id}"
          error_count += 1
        end
      end
    end

    puts "Update complete. Total rows in table: #{User.count}"
    puts "Updated #{updated_count} record(s). Hit #{error_count} error(s)."
  end

  desc "Verify update was successful"
  task :verify_user => :environment do
    verified_count = 0
    error_count = 0

    User.find_each do |user|
      if user.token == user.token_old
        verified_count += 1
      else
        puts "** Error values did not match for ID: #{user.id}"
        error_count += 1
      end
    end

    if verified_count == User.count
      puts "All #{verified_count} row(s) match."
    else
      puts "ERROR -- #{error_count} row(s) do not match"
    end
  end
end
