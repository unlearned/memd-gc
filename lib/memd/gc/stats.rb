module Memd
  module GC
    class Stats

      def initialize(host='localhost', port='11211')
        @host = host
        @port = port
      end

      def slabclasses
        items_hash.keys
      end

      def list
        items_hash.each do |no, item|
          cachedump(no).lines do |line|
            next if line.chomp == 'END'

            hoge, key, bytes, second = line.match(/^ITEM ([^ ]*) \[(\d*) b; (\d*)/).to_a
            second = second.to_i
            time = Time.at(second)

            data = {:item_number => no, :key => key, :bytes => bytes, :time => time}
            yield(data)
          end
        end
      end

      def stats_hash
        @stats_hash ||= stats.lines.each_with_object({}) do |l, h|
          res = l.chomp.match(/^STAT (\w+) ([^ ]+)/)
          next unless res
          value = (res[1] == 'version') ? res[2].to_s : res[2].to_i
          h[:"#{res[1]}"] = value
        end
      end

      def items_hash
        @items_hash ||= items.lines.each_with_object({}) do |l, h|
          res = l.chomp.match(/^STAT items:(\d+):(\w+) ([^ ]+)/)
          next unless res
          key_num = res[1].to_i
          h[key_num] = {} unless h.has_key? key_num
          h[key_num][:"#{res[2]}"] = res[3].to_i
        end
      end

      private

      def exec(cmd)
        MemcacheDo.exec(cmd, @host, @port)
      end

      def stats
        exec 'stats'
      end

      def items
        exec 'stats items'
      end

      def cachedump(slabclass)
        exec "stats cachedump #{slabclass} 0"
      end
    end
  end
end
