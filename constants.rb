# ============================================================
#  constants.rb — VM resource defaults
#
#  Override any value with an env var before vagrant up:
#    $env:VM_RAM_MB    = "16000"
#    $env:VM_CPUS      = "4"
#    $env:VM_DISK_GB   = "80"
#    $env:VM_TZ        = "America/New_York"
#    $env:VM_WORKSPACE = "C:\Users\yourname\projects"
# ============================================================

VM_RAM_MB       = ENV.fetch('VM_RAM_MB',    '25000').to_i
VM_CPUS         = ENV.fetch('VM_CPUS',      '8').to_i
VM_DISK_GB      = ENV.fetch('VM_DISK_GB',   '60').to_i
VM_TZ_DEFAULT   = ENV.fetch('VM_TZ',        'America/Bogota')
VM_WORKSPACE    = ENV.fetch('VM_WORKSPACE', ENV.fetch('WORKSPACE', 'V:/SharedFolder'))

# True when loaded by `packer build` — suppresses interactive prompts.
IS_PACKER_BUILD = ENV.key?('PACKER_BUILD_NAME')
