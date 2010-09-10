class Person < ActiveRecord::Base

  belongs_to :address

  has_one :student_class_assignment, :foreign_key => 'student_id', :dependent => :destroy

  validates_presence_of :gender

  validates_numericality_of :birth_year, :allow_nil => true, :only_integer => true, :greater_than => 1900, :less_than => Time.now.year
  validates_numericality_of :birth_month, :allow_nil => true, :only_integer => true, :greater_than => 0, :less_than => 13

  validate :name_is_not_blank


  def name
    "#{chinese_name}(#{english_first_name} #{english_last_name})"
  end

  def birth_info
    return '' if birth_month.blank? or birth_year.blank?
    "#{birth_month}/#{birth_year}"
  end
  
  def families
    families_as_parent = Family.find(:all, :conditions => "parent_one_id = #{self.id} or parent_two_id = #{self.id}")
    families_as_child = Family.find(:all, :conditions => "id in (select family_id from families_children where child_id = #{self.id})")
    families_as_parent + families_as_child
  end

  def email_and_phone_number_correct?(email, phone_number)
    puts "checking email and phone number for Person id => #{self.id}"
    if self.address
      self.addres.email_and_phone_number_correct? email, phone_number
    else
      self.families.detect do |family|
        family.address.email_and_phone_number_correct? email, phone_number
      end
    end
  end

  def self.find_people_on_record(english_first_name, english_last_name, email, phone_number)
    people_found_by_name = self.find_all_by_english_first_name_and_english_last_name english_first_name, english_last_name
    people_found_by_name.find_all do |person|
      person.email_and_phone_number_correct? email, phone_number
    end
  end

  private
  
  def name_is_not_blank
    return unless self.english_first_name.blank? or self.english_last_name.blank?
    return unless self.chinese_name.blank?
    errors.add_to_base('Engilsh Name or Chinese Name is required')
  end
end
