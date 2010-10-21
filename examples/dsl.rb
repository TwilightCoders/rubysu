require 'sudo'

include Sudo::DSL

sudo_start "-rfileutils"

puts sudo(File).read '/etc/shadow'

sudo(FileUtils).mkdir_p '/TEST_DIR/SUB_DIR'

sudo_stop


