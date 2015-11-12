require 'uri'
require 'cgi'

class Scanner
  STR_SCAN_SUMMARY_HEADER = "- SCAN SUMMARY -".freeze
  STR_SCAN_INFECTED_FILES = "Infected files".freeze
  COLOR_FAILURE = "red".freeze
  COLOR_SUCCESS = "green".freeze

  def initialize(log_filepath, room_id, token)
    @log_filepath = log_filepath
    @room_id = room_id
    @token = token
    @color = COLOR_FAILURE
    @report_lines = []

    raise "Missing log_filepath, room_id or token" if log_filepath.nil? || room_id.nil? || token.nil?
  end

  def run
    File.open(@log_filepath, "w") do |logger|
      finished = false
      IO.popen(scan_cmd) do |io|
        io.each do |line|
          if finished || line.index(STR_SCAN_SUMMARY_HEADER)
            finished = true
            @report_lines << line
          end
          logger.puts line
        end
      end
    end

    analyze
  end

  def notify
    system notify_cmd
  end

  private

  def scan_cmd
    "clamscan --infected --suppress-ok-results --recursive --detect-pua=yes --remove=no /"
  end

  def notify_cmd
    "curl -X POST \"#{hipchat_api_uri}\""
  end

  def hipchat_api_uri
    URI::HTTPS.build(
      host: "api.hipchat.com",
      path: "/v1/rooms/message",
      query: hipchat_api_query.map{ |k, v| "#{k}=#{v}" }.join('&')
    ).to_s
  end

  def hipchat_api_query
    {
      room_id: @room_id,
      auth_token: @token,
      notify: 1,
      color: @color,
      message_format: "html",
      from: "ClamAV",
      message: @message
    }
  end

  def analyze
    infected = @report_lines.detect { |line| line.start_with?(STR_SCAN_INFECTED_FILES) }
    if infected
      _, detections = infected.strip.split(": ")
      if detections.to_i == 0
        @color = COLOR_SUCCESS
      end
    end
    @message = "<strong>%s</strong><br>" % [@color == COLOR_SUCCESS ? "No viruses found" : "We have a problem"]
    @message << "Details: #{@log_filepath}<br>"
    @message << CGI.escape(@report_lines.join("<br>"))
  end
end


scan = Scanner.new(ENV["AVSCAN_LOG_FILE"], ENV["AVSCAN_HIPCHAT_ROOM_ID"], ENV["AVSCAN_HIPCHAT_ROOM_TOKEN"])
scan.run
scan.notify
