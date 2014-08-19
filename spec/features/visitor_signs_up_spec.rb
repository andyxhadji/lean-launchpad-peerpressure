require 'rails_helper'
require 'faker'
feature 'Visitor signs in/up' do
	include Features

	scenario 'with valid email and password' do
	  sign_up_with( Faker::Internet.email, 'thisisatest', 'thisisatest')
	  expect(page).to have_content('signed up successfully.')      
	end

	scenario 'without matching pw and confirmation' do
		sign_up_with('test@columbia.edu', 'thisisatest', 'notatestoh')
		expect(page).to have_content('Sign in')
	end
end