require 'rubygems'
require 'mechanize'

TERM_ID = 201210

if (ARGV.size < 2)
  abort "usage: ruby gradepoller.rb <student_no> <pin>"
end

grades = {}
username = ARGV[0]
password = ARGV[1]

agent = Mechanize.new
agent.ssl_version = 'SSLv3'

login_page = agent.get("https://aurora.umanitoba.ca/banprod/twbkwbis.P_ValLogin")
login_form = login_page.form("loginform")
login_form.sid = username
login_form.PIN = password

next_page = agent.submit(login_form)

if (next_page.uri != "https://aurora.umanitoba.ca/banprod/twbkwbis.P_ValLogin")  # If we are not redirected to the form
  # Select and submit current term for grades
  term_select_form = agent.get("https://aurora.umanitoba.ca/banprod/bwskogrd.P_ViewTermGrde").forms_with(:action => "bwskogrd.P_ViewGrde").first
  term_select_form.term_in = TERM_ID
  final_grade_page = agent.submit(term_select_form)
  
  data_tables = final_grade_page.search("table.datadisplaytable")
  grade_tables = data_tables ? data_tables[1] : nil
    
  if (grade_tables)
    seen_grade = false
    grade_tables.xpath("./tr").each do |row|
      columns = row.xpath("./td")
      if (columns.first.text.match(/^[0-9]{5}$/)) # If it is a course
        seen_grade = true
        puts " #{columns[6].text}\t#{columns[1].text}#{columns[2].text} -- #{columns[4].text}"
      end
    end
    puts "No grades have been posted." if !seen_grade
  else
    puts "No grades have been posted."
  end

else
  abort "Incorrect student name and PIN combination"
end
