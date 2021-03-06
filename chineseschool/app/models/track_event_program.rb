class TrackEventProgram < ActiveRecord::Base
  
  EVENT_TYPE_TOCS = 'TOCS'
  EVENT_TYPE_SOUTHERN_CA = 'Southern CA'
  
  PROGRAM_TYPE_STUDENT = 'Student'
  PROGRAM_TYPE_STUDENT_RELAY = 'Student Relay'
  PROGRAM_TYPE_PARENT = 'Parent'
  PROGRAM_TYPE_PARENT_RELAY = 'Parent Relay'
  
  belongs_to :school_year
  belongs_to :grade
  
  validates :school_year, :grade, :name, :event_type, :program_type, presence: true


  def max_sign_up_reached?(school_class)
    if (self.program_type == PROGRAM_TYPE_STUDENT_RELAY) and (self.relay_team_size > 7)
      current_signup_count = TrackEventSignup.count :conditions => ['track_event_program_id = ? AND student_class_assignments.school_class_id = ? AND school_year_id = ?', self.id, school_class.id, self.school_year.id],
                                                    :joins => 'JOIN student_class_assignments ON student_class_assignments.student_id = track_event_signups.student_id'
      puts "Current Signup Count => #{current_signup_count}"
      return true if current_signup_count >= self.relay_team_size
    end
    false
  end

  def self.find_current_year_parent_programs
    self.all :conditions => { :school_year_id => SchoolYear.current_school_year.id, :program_type => [ PROGRAM_TYPE_PARENT, PROGRAM_TYPE_PARENT_RELAY ] }
  end
  
  def self.find_by_grade(grade, school_year=SchoolYear.current_school_year)
    self.all :conditions => ['grade_id = ? AND school_year_id = ?', grade.id, school_year.id], :order => 'id ASC'
  end

  def self.find_by_school_age_for(student)
    programs = TrackEventProgram.find_by_grade(Grade.find_by_school_age(student.school_age_for(SchoolYear.current_school_year)))
    # This method would be called only for age-based movement of programs
    # There is a specific rule of only showing student individual programs as allowed sign-up
    programs.select {|program| program.program_type == PROGRAM_TYPE_STUDENT}
  end
  
  def self.find_tocs_programs_group_by_sort_keys(school_year=SchoolYear.current_school_year)
    tocs_programs = self.all :conditions => ['event_type = ? AND school_year_id = ?', EVENT_TYPE_TOCS, school_year.id], :order => 'sort_key ASC'
    tocs_programs_group_by_sort_keys = Hash.new { |hash, key| hash[key] = [] }
    tocs_programs.each { |tocs_program| tocs_programs_group_by_sort_keys[tocs_program.sort_key] << tocs_program }
    tocs_programs_group_by_sort_keys
  end
end
