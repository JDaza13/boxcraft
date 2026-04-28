# ============================================================
#  helpers.rb — shared Vagrantfile helpers
# ============================================================

require 'io/console'
require 'fileutils'

# Prompt for dev credentials on first `vagrant up`; persist/restore username.
def prompt_dev_credentials(profile_dir)
  vm_id_file   = File.join(profile_dir, '.vagrant', 'machines', 'default', 'virtualbox', 'id')
  user_file    = File.join(profile_dir, '.vagrant', 'dev_user')
  dev_user     = ENV['DEV_USER']
  dev_password = ENV['DEV_PASSWORD']

  if ARGV.first == 'up' && !IS_PACKER_BUILD && dev_user.nil? &&
     (!File.exist?(vm_id_file) || File.read(vm_id_file).strip.empty?)
    $stdout.print "\n>>> Username for dev user [dev]: "
    $stdout.flush
    input = $stdin.gets.chomp
    dev_user = input.empty? ? "dev" : input

    $stdout.print ">>> Set password for '#{dev_user}': "
    $stdout.flush
    dev_password = $stdin.noecho(&:gets).chomp
    puts ""

    FileUtils.mkdir_p(File.dirname(user_file))
    File.write(user_file, dev_user)
  end

  dev_user     ||= File.exist?(user_file) ? File.read(user_file).strip : "dev"
  dev_password ||= ""
  [dev_user, dev_password]
end

# Return the Packer-baked box if build.ps1 has been run, otherwise the upstream box.
def baked_box(profile_dir, baked:, upstream:)
  File.exist?(File.join(profile_dir, '.vagrant', 'packer_built')) ? baked : upstream
end

# Trigger: remove stale VirtualBox artefacts before a fresh `vagrant up`.
# Safe to call on every up — skips cleanup when a live machine ID is tracked.
def stale_vm_cleanup(config, vm_name, profile_dir)
  config.trigger.before :up do |t|
    t.name = "Clean stale VirtualBox artefacts"
    t.ruby do |env, _machine|
      id_file = File.join(profile_dir, '.vagrant', 'machines', 'default', 'virtualbox', 'id')
      next if File.exist?(id_file) && !File.read(id_file).strip.empty?

      `VBoxManage unregistervm "#{vm_name}" 2>&1`
      vbox_dir = File.join(ENV.fetch('USERPROFILE', Dir.home), 'VirtualBox VMs', vm_name)
      if Dir.exist?(vbox_dir)
        FileUtils.rm_rf(vbox_dir)
        env.ui.warn("Removed stale VM folder: #{vbox_dir}")
      end
    end
  end
end

# Wire up the standard three-step provisioning: system (skipped when baked) -> base -> tune.
def standard_provisioners(config, profile_dir:, dev_user:, dev_password:, dev_tz:, tune_reboot: false)
  use_baked = File.exist?(File.join(profile_dir, '.vagrant', 'packer_built'))

  unless use_baked
    config.vm.provision "file",
      source:      "provision-base.sh",
      destination: "/tmp/provision-base.sh"
    config.vm.provision "shell", name: "system", privileged: true,
      run:    "once",
      inline: "bash /tmp/provision-base.sh"
  end

  config.vm.provision "file",
    source:      "provision.sh",
    destination: "/tmp/provision.sh"
  config.vm.provision "shell", name: "base", privileged: true,
    run:    "once",
    reboot: true,
    env:    { "DEV_USER" => dev_user, "DEV_PASSWORD" => dev_password, "DEV_TZ" => dev_tz },
    inline: "bash /tmp/provision.sh"

  config.vm.provision "file",
    source:      "provision-tune.sh",
    destination: "/tmp/provision-tune.sh",
    run:         "always"
  config.vm.provision "shell", name: "tune", privileged: true,
    run:    "always",
    reboot: tune_reboot,
    env:    { "DEV_USER" => dev_user },
    inline: "bash /tmp/provision-tune.sh"
end
