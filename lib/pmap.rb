# Global variable for the default thread pool size.
$pmap_default_thread_count ||= 64

if (defined? RUBY_ENGINE) && (RUBY_ENGINE == 'jruby')
  require 'pmap/jruby'
else
  require 'pmap/vanilla'
end

module Enumerable
  include PMap
end
