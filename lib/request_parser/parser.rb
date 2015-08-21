module PackageProvider
  # Class for parsing package requests
  class Parser
    def logger
      PackageProvider.logger
    end

    def parse(request)
      tsd_request2parts(request).map do |package_part|
        repo, source_and_folder_override = package_part.split('|', 2)

        if source_and_folder_override.sub!(/\((.*)\)$/, '')
          folder_override = Regexp.last_match[1]
        end

        src_branch, src_commit_hash = source_and_folder_override.split(':', 2)

        if src_commit_hash.nil? && valid_commit_hash_format?(src_branch)
          src_commit_hash = src_branch
          src_branch = nil
        end

        resp = RepositoryRequest.new(repo, src_commit_hash, src_branch)

        folder_override.to_s.split(',').map do |fo|
          value = fo.split(/\s*>\s*/, 2)
          resp.add_folder_override(*value)
        end

        resp
      end
    end

    private

    def tsd_request2parts(request)
      regex_requests = Regexp.new(
        '((?:[^,()]+\|[^,()]+)(?:\([^()]*\))?)\s*(?=,\s*|$)')

      request.scan(regex_requests).map! { |x| x.first.strip }
    end

    def valid_commit_hash_format?(commit_hash)
      commit_hash.downcase =~ /\A[0-9a-f]+\z/
    end
  end
end
