resource "aws_iam_account_password_policy" "policy" {
  minimum_password_length = 10
  max_password_age = 90

  require_lowercase_characters = true
  require_uppercase_characters = true
  require_symbols = true
  require_numbers = true
  allow_users_to_change_password = true
}
