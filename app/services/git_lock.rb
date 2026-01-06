class GitLock
  # LOCK_FILE = Rails.root.join('tmp/wiki_repo/.git.lock')
  # TIMEOUT = 10 # секунд

  # def self.synchronize
  #   start_time = Time.now

  #   while File.exist?(LOCK_FILE)
  #     raise "Git lock timeout" if Time.now - start_time > TIMEOUT
  #     sleep 0.1
  #   end

  #   FileUtils.touch(LOCK_FILE)
  #   begin
  #     yield
  #   ensure
  #     File.delete(LOCK_FILE) if File.exist?(LOCK_FILE)
  #   end
  # end
end
