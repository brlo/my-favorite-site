SETTINGS = YAML.safe_load(
  ::File.read(
    "config/settings.yml"
  ),
  aliases: true
)[Rails.env]
