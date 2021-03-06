class Api::V1::MessageController < ActionController::Base
  include LineBotSetting
  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]
  
  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          # message = {
          #   type: 'text',
          #   text: event.message['text']
          # }
          message = {
            "type": "template",
            "altText": "あなたの性別を教えてください",
            "template": {
                "type": "confirm",
                "text": "あなたの性別を教えてください",
                "actions": [
                    {
                      "type": "message",
                      "label": "男性",
                      "text": "male"
                    },
                    {
                      "type": "message",
                      "label": "女性",
                      "text": "female"
                    }
                ]
            }
          }
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    end

    # Don't forget to return a successful response
    "OK"
  end
end
