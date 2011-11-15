module Ecore
  module UniqueIDGenerator

      # generates a new unique id and returs it
      def gen_unique_id(tname=:documents)
        id = 0
        until (id.is_a?(String) && id.match(/^(?=[a-zA-Z]).{8}$/) && !id.include?(','))
          id = SecureRandom.hex(4)
        end
        if Ecore::db[tname].first(:id => id)
          File.open('duplication_warnings','a'){ |f| f.write("#{tname}: #{Time.now.strftime('%Y-%m-%d %H:%M:%s')} - #{id}\n") }
          gen_unique_id
        end
        id
      end


  end
end
