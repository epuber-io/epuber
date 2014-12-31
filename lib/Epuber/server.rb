# encoding: utf-8

require 'sinatra/base'

require_relative 'book'


module Epuber
  class Server < Sinatra::Base
    class << self
      # @return [Epuber::Book::Book]
      #
      attr_accessor :book
    end

    # @return [Epuber::Book::Book]
    #
    def book
      self.class.book
    end


    # -------------------------------------------------- #

    # @!group Sinatra things

    enable :sessions

    connections = []

    get '/book' do
      book.to_s
    end

    get '/text' do
      session[:text] || 'blaf'
    end

    get %r{/text/} do
      path = request.path_info.sub(%r{/text/}, '')
      File.read(path)
    end

    get '/time' do
      File.read('../json_ajax_experiment.html')
    end

    get '/time_ajax' do
      stream(:keep_open) do |out|
        connections << out
      end
    end

    Thread.new {
      loop do
        sleep(1)

        puts "Checking, connections count = #{connections.count}"

        connections.each { |out|
          time = Time.now.to_s
          out << time
          out.close
          puts "Just sent #{time}"
        }

        connections.reject!(&:closed?)
      end
    }
  end
end


