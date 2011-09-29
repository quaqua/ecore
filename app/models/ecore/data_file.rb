require 'fileutils'

module Ecore
  class DataFile < ActiveRecord::Base
    cattr_accessor :file_path

    acts_as_node

    attr_accessor :file

    after_save :save_to_datastore
    after_destroy :remove_from_datastore

    # returns full filename
    def filename
      ::File::join(self.class.file_path,id,id)
    end

    private

    # saves @file to datastore
    def save_to_datastore
      return unless @file
      FileUtils::mkdir_p(File::dirname(filename)) unless File::exists?(File::dirname(filename))
      File::open(filename, "wb") { |f| f.write(@file.read) }
    end

    def remove_from_datastore
      FileUtils::rm_f(filename)
      if Dir.glob(File::dirname(filename)+'/*').size == 0
        FileUtils::rm_rf(File::dirname(filename))
      end
    end

  end
end
