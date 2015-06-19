module RGen
  module RevisionControl
    class Git < Base
      def build
        if Dir["#{local}/*"].empty?
          FileUtils.rm_rf(local.to_s)
          # Not using the regular 'git' method here since the local dir doesn't exist to CD into
          system "git clone #{remote} #{local}"
        else
          fail "The requested workspace is not empty: #{local}"
        end
      end

      def checkout(path = nil, options = {})
        paths, options = clean_path(path, options)
        # Pulls latest metadata from server, does not change workspace
        git 'fetch', options

        version = options[:version] || current_branch

        if version == 'HEAD'
          puts "Sorry, but you are not currently on a branch and I don't know which branch you want to checkout"
          puts 'Please supply a branch name as the version to checkout the latest version of it, e.g. rgen rc co -v develop'
          exit 1
        end

        if options[:force]
          git 'reset HEAD'
          git "checkout #{version} #{paths.join(' ')}", options
        else
          if paths.size > 1 || paths.first != local.to_s
            fail 'The Git driver does not support partial merge checkout, it has to be the whole workspace'
          end
          git 'reset HEAD'
          res = git 'stash', options
          stashed = !res.any? { |l| l =~ /^No local changes to save/ }
          git "checkout #{version}", options
          if stashed
            result = git 'stash pop', { check_errors: false }.merge(options)
            conflicts = []
            result.each do |line|
              if line =~ /CONFLICT.* (.*)$/
                conflicts << Regexp.last_match(1)
              end
            end
            git 'reset HEAD'
            unless conflicts.empty?
              RGen.log.info ''
              RGen.log.error 'Your local changes could not automatically merged into the following files, open them to fix the conflicts:'
              conflicts.each do |conflict|
                RGen.log.error "  #{conflict}"
              end
            end
          end
        end
        paths
      end

      def checkin(path = nil, options = {})
        paths, options = clean_path(path, options)
        # Can't check in unless we have the latest
        if options[:force] && !options[:initial]
          # Locally check in the given files
          checkin(paths.join(' '), local: true, verbose: false, comment: options[:comment])
          local_rev = current_commit
          # Pull latest
          checkout
          # Restore the given files to our previous version
          git("checkout #{local_rev} -- #{paths.join(' ')}")
          # Then proceed with checking them in as latest
        else
          checkout unless options[:initial]
        end
        cmd = 'add'
        cmd += ' -u' unless options[:unmanaged]
        cmd += " #{paths.join(' ')}"
        git cmd, options
        if changes_pending_commit?
          cmd = 'commit'
          if options[:comment] && !options[:comment].strip.empty?
            cmd += " -m \"#{options[:comment].strip}\""
          else
            cmd += " -m \"No comment!\""
          end
          if options[:author]
            if options[:author].respond_to?(:name_and_email)
              author =  options[:author].name_and_email
            else
              author = "#{options[:author]} <>"
            end
            cmd += " --author=\"#{author}\""
          end
          if options[:time]
            cmd += " --date=\"#{options[:time].strftime('%a %b %e %H:%M:%S %Y %z')}\""
          end
          git cmd, options
        end
        git "push origin #{current_branch}" unless options[:local]
        paths
      end

      def changes(dir = nil, options = {})
        paths, options = clean_path(dir, options)
        options = {
          verbose: false
        }.merge(options)
        # Pulls latest metadata from server, does not change workspace
        git 'fetch', options

        version = options[:version] || 'HEAD'
        objects = {}

        objects[:added]   = git("diff --name-only --diff-filter=A #{version} #{paths.first}", options).map(&:strip)
        objects[:removed] = git("diff --name-only --diff-filter=D #{version} #{paths.first}", options).map(&:strip)
        objects[:changed] = git("diff --name-only --diff-filter=M #{version} #{paths.first}", options).map(&:strip)

        objects[:present] = !objects[:added].empty? || !objects[:removed].empty? || !objects[:changed].empty?
        # Return full paths
        objects[:added].map! { |i| "#{paths.first}/" + i }
        objects[:removed].map! { |i| "#{paths.first}/" + i }
        objects[:changed].map! { |i| "#{paths.first}/" + i }
        objects
      end

      def local_modifications(dir = nil, options = {})
        paths, options = clean_path(dir, options)
        options = {
          verbose: false
        }.merge(options)

        cmd = 'diff --name-only'
        dir = " #{paths.first}"
        unstaged = git(cmd + dir, options).map(&:strip)
        staged = git(cmd + ' --cached' + dir, options).map(&:strip)
        unstaged + staged
      end

      def unmanaged(dir = nil, options = {})
        paths, options = clean_path(dir, options)
        options = {
          verbose: false
        }.merge(options)
        cmd = "ls-files #{paths.first} --exclude-standard --others"
        git(cmd, options).map(&:strip)
      end

      def diff_cmd(file, version)
        "git difftool --tool tkdiff -y #{prefix_tag(version)} #{file}"
      end

      def tag(id, options = {})
        id = VersionString.new(id)
        id = id.prefixed if id.semantic?
        if options[:comment]
          git "tag -a #{id} -m \"#{options[:comment]}\""
        else
          git "tag #{id}"
        end
        git "push origin #{id}"
      end

      def root
        Pathname.new(git('rev-parse --show-toplevel', verbose: false).first.strip)
      end

      def current_branch
        git('rev-parse --abbrev-ref HEAD', verbose: false).first
      end

      # Returns true if the given tag already exists
      def tag_exists?(tag)
        git('fetch', verbose: false) unless @all_tags_fetched
        @all_tags_fetched = true
        git('tag', verbose: false).include?(tag.to_s)
      end

      private

      def create_gitignore
        c = RGen::Generator::Compiler.new
        c.compile "#{RGen.top}/templates/git/gitignore.erb",
                  output_directory:  local,
                  quiet:             true,
                  check_for_changes: false
        FileUtils.mv "#{local}/gitignore", "#{local}/.gitignore"
      end

      def changes_pending_commit?
        !(git('status --verbose', verbose: false).last =~ /^(no changes|nothing to commit)/)
      end

      def current_commit
        git('rev-parse HEAD', verbose: false).first
      end

      def initialize_local_dir
        super
        unless initialized?
          RGen.log.debug "Initializing Git workspace at #{local}"
          git 'init'
          git "remote add origin #{remote}"
        end
      end

      def initialized?
        File.exist?("#{local}/.git")
      end

      # Execute a git operation, the resultant output is returned in an array
      def git(command, options = {})
        options = {
          check_errors: true,
          verbose:      true
        }.merge(options)
        output = []
        if options[:verbose]
          RGen.log.info "git #{command}"
          RGen.log.info ''
        end
        Dir.chdir local do
          Open3.popen2e("git #{command}") do |_stdin, stdout_err, wait_thr|
            while line = stdout_err.gets
              RGen.log.info line.strip if options[:verbose]
              unless line.strip.empty?
                output << line.strip
              end
            end

            exit_status = wait_thr.value
            unless exit_status.success?
              if options[:check_errors]
                fail GitError, "This command failed: 'git #{command}'"
              end
            end
          end
        end
        output
      end
    end
  end
end