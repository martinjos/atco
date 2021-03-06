$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'open3'
require 'tempfile'  
require 'atco/location'
require 'atco/journey'
require 'atco/stop'


module Atco
  VERSION = '0.0.1'
  
  class << self
    
    @path = nil
    @@methods = {
      'QH' => :bank_holiday,
      'QP' => :operator,
      'QB' => :additional_location_info,
      'QL' => :location,
      'QT' => :destination,
      'QI' => :intermediate,
      'QO' => :origin,
      'QS' => :journey_header,
    }
    
    def parse(file)
      @path = File.expand_path(file)
      
      objects = []
      current_journey = nil
      current_location = nil
      locations = []
      journeys = {}
      header = nil
      
      File.foreach(@path).each_with_index do |line,i|
        if i == 0
          header = parse_header(line)
          next
        end
        method = @@methods[line[0,2]]
        next if method.nil?
        object = self.send("parse_#{method}", line)
        if method == :journey_header
          current_journey = object
        elsif method == :location
          current_location = object
        elsif method == :additional_location_info
          locations << Location.new(current_location, object)
        end

        if current_journey
          if journeys[current_journey[:unique_journey_identifier]]
            journeys[current_journey[:unique_journey_identifier]].stops << Stop.new(object)
          else
            journeys[current_journey[:unique_journey_identifier]] = Journey.new(object)
          end
        end
        objects << object
      end
      return {:header => header, :locations => locations, :journeys => journeys}
    end
    
    def parse_header(string)
      {
        :file_type => string[0,8],
        :version => "#{string[8,2].to_i}.#{string[10,2].to_i}",
        :file_originator => string[12,32].strip!,
        :source_product => string[44,16].strip!,
        :production_datetime => string[60,14]
      } 
    end
    
    def parse_bank_holiday(string)
      {
        :record_identity => string[0,2],
        :transaction_type => string[2,1],
        :date_of_bank_holiday => string[3,8]
      }
    end
    
    def parse_operator(string)
      {
        :record_identity => string[0,2],
        :transaction_type => string[2,1],
        :operator => parse_value(string[3,4]),
        :operator_short_form => parse_value(string[7,24]),
        :operator_legal_name => parse_value(string[31,48])
      }
    end

    def parse_additional_location_info(string)
      {
        :record_identity => string[0,2],
        :transaction_type => string[2,1],
        :location => string[3,12].strip,
        :grid_reference_easting => parse_value(string[15,8]),
        :grid_reference_northing => parse_value(string[23,8])
      }
    end

    def parse_location(string)
      {
        :record_identity => string[0,2],
        :transaction_type => string[2,1],
        :location => parse_value(string[3,12]),
        :full_location => parse_value(string[15,48]),
        :gazetteer_code => string[63,1]
      }
    end

    def parse_destination(string)
      {
        :record_identity => string[0,2],
        :location => string[2,12],
        :published_arrival_time => string[14,4],
        :bay_number => parse_value(string[18,3]),
        :timing_point_indicator => string[21,2],
        :fare_stage_indicator => string[23,2]
      }
    end

    def parse_intermediate(string)
      {
        :record_identity => string[0,2],
        :location => string[2,12],
        :published_arrival_time => string[14,4],
        :published_departure_time => string[18,4],
        :activity_flag => string[22,1],
        :bay_number => parse_value(string[23,3]),
        :timing_point_indicator => string[26,2],
        :fare_stage_indicator => string[28,2]
      }
    end

    def parse_origin(string)
      {
        :record_identity => string[0,2],
        :location => string[2,12],
        :published_departure_time => string[14,4],
        :bay_number => parse_value(string[18,3]),
        :timing_point_indicator => string[21,2],
        :fare_stage_indicator => string[23,2]
      }
    end

    def parse_journey_header(string)
      {
        :record_identity => string[0,2],
        :transaction_type => string[2,1],
        :operator => string[3,4].strip,
        :unique_journey_identifier => string[7,6],
        :first_date_of_operation => parse_value(string[13,8]),
        :last_date_of_operation => parse_value(string[21,8]),
        :operates_on_mondays => string[29,1],
        :operates_on_tuesdays => string[30,1],
        :operates_on_wednesdays => string[31,1],
        :operates_on_thursdays => string[32,1],
        :operates_on_fridays => string[33,1],
        :operates_on_saturdays => string[34,1],
        :operates_on_sundays => string[35,1],
        :school_term_time => parse_value(string[36,1]),
        :bank_holidays => parse_value(string[37,1]),
        :route_number => parse_value(string[38,4]),
        :running_board => parse_value(string[42,6]),
        :vehicle_type => parse_value(string[48,8]),
        :registration_number => parse_value(string[56,8]),
        :route_direction => string[64,1]
      }
    end
    
    def parse_value(value)
      return value.strip if value
    end
  end
  
end
