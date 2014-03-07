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
    # create fields for tags and index it
    field :tags_array, :type => Array, :default => []
    index({ tags_array: 1 })

    # add callback to save tags index
    after_save do |document|
      document.class.save_tags_index! if document.tags_array_changed?
    end

    # enable indexing as default
    enable_tags_index!
  end

  module ClassMethods
    # returns an array of distinct ordered list of tags defined in all documents

    def tagged_with(tag)
      self.any_in(:tags_array => [tag])
    end

    def tagged_with_all(*tags)
      self.all_in(:tags_array => tags.flatten)
    end

    def tagged_with_any(*tags)
      self.any_in(:tags_array => tags.flatten)
    end

    def tags
      index_tags_now! if need_to_index_tags and @do_tags_index
      tags_index_collection.find.sort(_id: 1).to_a.map{ |r| r["_id"]}
    end

    # retrieve the list of tags with weight (i.e. count), this is useful for
    # creating tag clouds
    def tags_with_weight
      index_tags_now! if need_to_index_tags and @do_tags_index
      tags_index_collection.find.sort(_id: 1).to_a.map{ |r| [r["_id"], r["matches"]] }
    end

    def disable_tags_index!
      @do_tags_index = false
    end

    def enable_tags_index!
      @do_tags_index = true
    end


    def need_to_index_tags
      @need_to_index_tags ||= false
    end


    def tags_separator(separator = nil)
      @tags_separator = separator if separator
      @tags_separator || ','
    end

    def tags_index_collection_name
      "#{collection_name}_tags_index"
    end

    def tags_index_collection
      @tags_index_collection ||= Moped::Collection.new(self.collection.database, tags_index_collection_name)
    end

    def save_tags_index!
      return unless @do_tags_index

      @need_to_index_tags = true
    end


    def index_tags_now!
      # tag indexing was incredibly slow using map_reduce
      # http://docs.mongodb.org/manual/core/map-reduce/ suggests using the aggregation pipeline

      tags_index_pipeline = [
        {"$unwind" => "$tags_array"},
        {"$group" => {_id: "$tags_array", matches: {"$sum" => 1} } },
        {"$sort" => {_id: 1}}
      ]

      # It would be good to use the "$out" pipeline step, to save this aggregation
      # to a collection (instead of array), but this is only available in unreleased Mongo 2.6

      results = self.unscoped.collection.aggregate(*tags_index_pipeline)

      results.each { |r| tags_index_collection.find(_id: r["_id"]).upsert(r) }

      @need_to_index_tags = false
    end

    def find_related(document_array, limit = 0, pipeline_injection = [])

      total_tags =  document_array.map(&:tags_array).flatten
      total_ids =  document_array.map(&:id).flatten.uniq

      related_pipeline = [
        {"$match" => { tags_array:  {"$in" => total_tags}, _id: {"$nin" => total_ids}} },
        {"$unwind" => "$tags_array"},
        {"$match" => {tags_array: {"$in" => total_tags} } },
        {"$group" => {_id: "$_id", matches: {"$sum" => 1} } },
        {"$sort" => {matches: -1} }
      ]
      related_pipeline.push({"$limit" => limit}) if  limit > 0

      related_pipeline = (pipeline_injection.kind_of?(Array) ?
                related_pipeline.insert(0, *pipeline_injection)
              : related_pipeline.insert(0, pipeline_injection) )

      related = self.collection.aggregate(*related_pipeline)

      ordering = {}
      related.each_with_index { |x, i| ordering[x["_id"]] = i }
      self.find(related.map { |x| x["_id"] }).sort_by { |o| ordering[o.id]  }
    end

  end


  def tags
    (tags_array || []).join(self.class.tags_separator)
  end

  def tags=(tags)
    if tags.present?
      self.tags_array = tags.split(self.class.tags_separator).map(&:strip).reject(&:blank?)
    else
     self.tags_array = []
    end
  end

  def save_tags_index!
    self.class.save_tags_index!
  end


  # Find by related
  # find items related to this item by which have the most tags the same
  # http://dev.mensfeld.pl/2014/02/mongoid-and-aggregation-framework-get-similar-elements-based-on-tags-ordered-by-total-number-of-matches-similarity-level/

  def find_related(limit = 0, pipeline_injection = [])
    self.class.find_related([self], limit, pipeline_injection)
  end


end
