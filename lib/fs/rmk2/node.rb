# frozen_string_literal: true

module FS
  module Rmk2
    class Node

      class << self
        attr_accessor :logger, :datadir

        def init(mp, logger: LOGGER)
          @logger = logger
          return unless @mounted ||= system("mount #{mp}")

          @datadir = File.join(mp,
                               *%w[home root .local share remarkable xochitl])
          Dir.glob(File.join(@datadir, '*.metadata')) do |fn|
            item_by_id(File.basename(fn, '.metadata'))
          end
        end

        def id_json(id)
          require 'json'
          @id_json ||= {}
          fn = File.join(@datadir, "#{id}.metadata")
          @id_json[id] ||= JSON.load(File.open(fn))
        rescue Errno::ENOENT => ee
          @logger.error("An error: #{ee}")
          nil
        end

        def item_by_id(id, data = nil)
          @item_by_id ||= {}
          return nil if id == 'trash' || id.empty?
          @item_by_id[id] ||= self.new id, data
        end

        def all
          @item_by_id.values
        end
      end

      attr_accessor :data, :id
      attr_reader :parent

      def initialize(id, data = nil)
        @id = id
        if data
          @data = data
        else
          @data = self.class.id_json(id)
        end
        unless @data
          error("Failed to set data for #{id}")
          return
        end

        @parent = self.class.item_by_id @data['parent']
        @parent.add_kid(self) if @parent
        @kids = folder? ? [] : nil
      end

      def add_kid(kid)
        if @kids.respond_to?(:push)
          @kids.push(kid)
        else
          error("Trying to add a kid to #{id}, but it is not a folder (#{data['type']})")
        end
      end

      def error(...)
        self.class.logger.error(...)
      end

      def info(...)
        self.class.logger.info(...)
      end

      def regular?
        data['type'] == 'DocumentType'
      end

      def folder?
        data['type'] == 'CollectionType'
      end

      def trash?
        data['parent'] == 'trash'
      end

      def name
        data['visibleName']
      end

      def to_s
        name + (folder? ? '/' : '')
      end

      def top?
        @parent.nil?
      end

      def to_a
        @kids || []
      end
    end

  end
end
