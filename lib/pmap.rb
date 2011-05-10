# Global variable for the default thread pool size.
$pmap_default_thread_count ||= 64

require 'pmap/vanilla'

module Enumerable
  include PMap
end
