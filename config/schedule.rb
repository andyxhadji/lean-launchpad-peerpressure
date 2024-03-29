# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
# 
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, "/var/www/dev.vigme.com/log/cron/rankings.log"
every 1.day, :at => '4:30 am' do
	rake "rankings:update"
end

set :output, "/var/www/dev.vigme.com/log/cron/kimono.log"
every 1.day, :at => '3:30 am' do
        rake "kimono:coolspotters"
end

set :output, "/var/www/dev.vigme.com/log/cron/update_products.log"
every 1.day, :at => '5:00 am' do
        rake "update:celebrity_products"
end
