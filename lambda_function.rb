require 'json'
require 'twitter'
require 'httparty'
require 'nokogiri'

def lambda_handler(event:, context:)
    twitter = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV['CONSUMER_KEY']
        config.consumer_secret = ENV['CONSUMER_SECRET']
        config.access_token = ENV['ACCESS_TOKEN']
        config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    latest_tweets = twitter.user_timeline('esrosn')

    previous_links = latest_tweets.map do |tweet|
        if tweet.urls.any?
            tweet.urls[0].expanded_url
        end
    end

    rss = HTTParty.get('https://www.designernews.co/?format=rss')
    doc = Nokogiri::XML(rss)

    doc.css('item').take(5).each do |item|
        title = item.css('title').text
        link = item.css('description').text

        unless link.start_with?('http')
            link = item.css('link').text
        end

        unless previous_links.include?(link)
            twitter.update("#{title} #{link}")
        end
    end
    { statusCode: 200, body: JSON.generate('Hello from Lambda!') }
end



