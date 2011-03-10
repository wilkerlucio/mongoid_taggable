# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongoid::Taggable
  extend ActiveSupport::Concern

  included do
    class_inheritable_reader :tags_field
    class_inheritable_accessor :tags_separator, :tag_aggregation,
      :instance_writer => false

    delegate :convert_string_tags_to_array, :aggregate_tags, :to => 'self.class'

    set_callback :create,  :after, :aggregate_tags
    set_callback :destroy, :after, :aggregate_tags
    set_callback :save,    :after, :aggregate_tags, :if => proc { previous_changes.include?(tags_field.to_s) }
  end

  module ClassMethods
    # Macro to declare a document class as taggable, specify field name
    # for tags, and set options for tagging behavior.
    #
    # @example Define a taggable document.
    #
    #   class Article
    #     include Mongoid::Document
    #     include Mongoid::Taggable
    #     taggable :keywords, :separator => ' ', :aggregation => true
    #   end
    #
    # @param [ Symbol ] field The name of the field for tags.
    # @param [ Hash ] options Options for taggable behavior.
    #
    # @option options [ String ] :separator The tag separator to
    #   convert from; defaults to ','
    # @option options [ true, false ] :aggregation Whether or not to
    #   aggregate counts of tags within the document collection using
    #   map/reduce; defaults to false
    def taggable(*args)
      options = args.extract_options!
      options.reverse_merge!(
        :separator => ',',
        :aggregation => false
      )

      write_inheritable_attribute(:tags_field, args.blank? ? :tags : args.shift)
      self.tags_separator  = options[:separator]
      self.tag_aggregation = options[:aggregation]

      field tags_field, :type => Array
      index tags_field

      define_tag_field_accessors(tags_field)
    end

    # get an array with all defined tags for this model, this list returns
    # an array of distinct ordered list of tags defined in all documents
    # of this model
    def tags
      db.collection(tags_aggregation_collection).find.to_a.map{ |r| r["_id"] }
    end

    # retrieve the list of tags with weight(count), this is useful for
    # creating tag clouds
    def tags_with_weight
      db.collection(tags_aggregation_collection).find.to_a.map{ |r| [r["_id"], r["value"]] }
    end

    # Find documents tagged with all tags passed as a parameter, given
    # as an Array or a String using the configured separator.
    #
    # @example Find matching all tags in an Array.
    #   Article.tagged_with(['ruby', 'mongodb'])
    # @example Find matching all tags in a String.
    #   Article.tagged_with('ruby, mongodb')
    #
    # @param [ Array<String, Symbol>, String ] _tags Tags to match.
    # @return [ Criteria ] A new criteria.
    def tagged_with(_tags)
      _tags = convert_string_tags_to_array(_tags) if _tags.is_a? String
      criteria.all_in(tags_field => _tags)
    end

    # Collection name for storing results of tag count aggregation
    def tags_aggregation_collection
      @tags_aggregation_collection ||= "#{collection_name}_tags_aggregation"
    end

    # Execute map/reduce operation to aggregate tag counts for document
    # class
    def aggregate_tags
      return unless tag_aggregation

      map = "function() {
        if (!this.#{tags_field}) {
          return;
        }

        for (index in this.#{tags_field}) {
          emit(this.#{tags_field}[index], 1);
        }
      }"

      reduce = "function(previous, current) {
        var count = 0;

        for (index in current) {
          count += current[index]
        }

        return count;
      }"

      collection.master.map_reduce(map, reduce, :out => tags_aggregation_collection)
    end

  private

    # Helper method to convert a String to an Array based on the
    # configured tag separator.
    def convert_string_tags_to_array(_tags)
      (_tags).split(tags_separator).map(&:strip)
    end

    # Define modifier for the configured tag field name that overrides
    # the default to transparently convert tags given as a String.
    def define_tag_field_accessors(name)
      define_method "#{name}_with_taggable=" do |values|
        values = convert_string_tags_to_array(values) if values.is_a? String
        send("#{name}_without_taggable=", values.reject(&:blank?))
      end
      alias_method_chain "#{name}=", :taggable
    end
  end
end
