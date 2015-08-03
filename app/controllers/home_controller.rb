class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:csp_report]

  def index
    @featured_startups = Startup.where(featured: true)
    @navbar_start_transparent = true
    @skip_container = true
  end

  def faculty
    @faculty = {
      advisory_board: [
        { name: "Kris Gopalakrishnan", title: "Chief Mentor, Co-Founder Infosys" },
        { name: "Kiran Karnik", title: "Board Member, Reserve Bank of India" },
        { name: "Dr. H.K. Mittal", title: "Head, NSTEDB, Department of Science and Technology, Government of India" },
        { name: "Rajan Mathews", title: "Director Generator, Cellular Operators Association of India" },
        { name: "Annie Mathew", title: "Research in Motion" },
        { name: "Murali Gopalan", title: "Charter Member, TIE" },
        { name: "R.K. Nair", title: "Ex CEO, Technopark" },
        { name: "Dr. K.C.C. Nair", title: "Ex CFO, Technopark" },
        { name: "Dr. Jayasankar Prasad", title: "CEO, Kerala Startup Mission" },
        { name: "K.T. Rajagopalan", title: "Ex Director, State Bank of Travancore" },
        { name: "Dr. B. Anil", title: "Principal, Government Engineering College, Barton Hill" }
      ],
      visiting_faculty: [
        { name: "Abhishek Goyal", title: "Co-Founder, Traxcn Labs", key_skills: "Business Ideas", linked_in: "https://www.linkedin.com/in/abhishekgoyal" },
        { name: "Nishant Verman", title: "Director of Corporate Development, Flipkart", key_skills: "Acquisitions", linked_in: "https://in.linkedin.com/in/nishantverman" },
        { name: "Sharad Sharma", title: "Co-Founder, Ispirt", key_skills: "Angel Investments", linked_in: "https://www.linkedin.com/in/sharadsharma" },
        { name: "Karan Mohla", title: "Executive Director, IDG Ventures", key_skills: "Angel Investments", linked_in: "https://in.linkedin.com/pub/karan-mohla/0/998/153" },
        { name: "Sunil Kalra", title: "Professional Angel Investor", key_skills: "Angel Investments", linked_in: "https://www.linkedin.com/pub/sunil-kalra/21/9a6/a12" },
        { name: "Alok Bajpai", title: "Co-Founder IXIGO", key_skills: "Product Strategy", linked_in: "https://www.linkedin.com/in/alokebajpai" },
        { name: "Krishnakumar Natarajan", title: "Co-Founder Mindtree", key_skills: "Scaling up", linked_in: "https://www.linkedin.com/pub/krishnakumar-natarajan/0/338/839" },
        { name: "George Brody", title: "Founder, Globe Ranger", key_skills: "Product Strategy", linked_in: "https://www.linkedin.com/in/georgebrodyprofile" },
        { name: "Ganesh Lakshminarayan", title: "Consultant @ Sequoia Capital", key_skills: "Scaling up", linked_in: "https://www.linkedin.com/in/ganeshls" },
        { name: "Sasha Mirchandani", title: "Founder, Kae Capital", key_skills: "Angel Investments", linked_in: "https://www.linkedin.com/pub/sasha-mirchandani/13/489/81a" },
        { name: "Phanindra Sama", title: "Founder, Red Bus", key_skills: "Business Ideas", linked_in: "https://www.linkedin.com/pub/sasha-mirchandani/13/489/81a" },
        { name: "Nandakumar", title: "CEO, SunTec", key_skills: "Scaling up", linked_in: "https://in.linkedin.com/in/knandakumar" },
        { name: "Aakrit Vaish", title: "Co-Founder, Haptik", key_skills: "Product Strategy", linked_in: "https://www.linkedin.com/in/aakrit" },
        { name: "Ravi Kiran", title: "Co-Founder, Venture Nursery", key_skills: "Accelerating Startups", linked_in: "http://in.linkedin.com/in/ravitwo" },
        { name: "Shradha Sharma", title: "Founder, Yourstory", key_skills: "Public Relations", linked_in: "https://www.linkedin.com/in/sharmashradha" },
        { name: "Amit Gupta", title: "Co-Founder InMobi", key_skills: "Startup Revenues", linked_in: "https://www.linkedin.com/in/amitgupta007" },
        { name: "Freeman Murray", title: "Founder, Jaaga", key_skills: "Startup Prototyping", linked_in: "http://in.linkedin.com/in/freemanmurray" },
        { name: "Shashi Dharan", title: "Founder of BE Group", key_skills: "Public Relations", linked_in: "https://www.linkedin.com/pub/shashi-dharan/9/583/396" }
      ],
      team: [
        { name: "Sanjay Vijayakumar", title: "Chairman" },
        { name: "Pranav Suresh", title: "CEO" },
        { name: "Vishnu Gopal", title: "CTO" },
        { name: "Gautham", title: "COO" },
        { name: "Rohan Kalani", title: "AVP Operations & Finance"},
        { name: "Hari Gopal", title: "Engineering Architect"},
        { name: "Joby Joseph", title: "Product" },
        { name: "Naveen Narayanan", title: "Academic Relations" },
        { name: "Daniel Jeevan", title: "Digital Strategist" },
        { name: "Aditya Nair", title: "Governance & Strategic Initiatives" },
        { name: "Abdul Jaleel", title: "Software Engineer"},
        { name: "Sreerag Dileep", title: "Governance & Operations" },
        { name: "Dinnu Nijo", title: "Incubation" },
        { name: "Sebin John Mathew", title: "Communications & Operations" },
        { name: "Shameem P", title: "Client Relations"},
        { name: "Kiran Baby", title:	"Client Relations" },
        { name: "Manoj Krishnan", title: "Head, Startup Studio" },
        { name: "Varun M", title: "Academic & Client Relations" },
        { name: "Vasudeva Rao Thumati", title: "Operations"},
        { name: "Kireeti Varma", title: "Operations"},
        { name: "Bharath Binnam", title: "Operations"},
        { name: "Mini M", title: "Administration"},
        { name: "Shajahan Ibrahim", title: "Administration" }
      ]
    }

    @skip_container = true
  end

  def about
  end

  private

  def faculty_image_path(type, image)
    "faculty/#{type}/". #Images are stored in a subfolder in faculty/
      +(image).
      gsub('Dr. ', ''). #Remove Salutations
      gsub('.', '_'). #Convert initials to underscores
      gsub(' ', '_'). #Convert spaces to underscores
      underscore. #Convert to underscore case
      gsub(/_+/, '_'). #Convert multiple underscores to one
      +(".png") #PNG image
  end

  helper_method :faculty_image_path
end
