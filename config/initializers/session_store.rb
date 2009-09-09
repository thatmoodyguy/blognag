# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_blognag_session',
  :secret      => '4037d48a0f1aeafa58293ab4cde5ccc6b7788579be19adad1b79cd8eed4cd804e84035669e04e785a074875ba420862b226688713ac76ab2d5f0727a550bc374'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
