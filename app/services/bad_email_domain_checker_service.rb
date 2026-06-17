class BadEmailDomainCheckerService
  class << self
    # BadEmailDomainCheckerService.disposable_email?('test@10minutemail.com')
    def disposable_email?(email)
      return true if email.blank?

      domain_parts = email.split('@')[1].split('.')
      bl = blacklist

      (domain_parts.count - 1).times do |i|
        return true if bl.include?(domain_parts[i..-1].join('.'))
      end
      false
    end

    def blacklist
      File.readlines('db/disposable_email_blocklist.conf', chomp: true).to_set.freeze
    end
  end
end

