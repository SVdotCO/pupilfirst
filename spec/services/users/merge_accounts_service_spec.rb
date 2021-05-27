require 'rails_helper'

describe Users::MergeAccountsService do
  subject { described_class }

  let(:school) { create :school, :current }
  let!(:new_user) { create :user, school: school }
  let!(:old_user) { create :user, school: school }

  # Create courses and student profiles
  let!(:course_1) { create :course, school: school }
  let!(:course_2) { create :course, school: school }
  let!(:level_1_c1) { create :level, :one, course: course_1 }
  let!(:level_1_c2) { create :level, :one, course: course_2 }
  let!(:level_2_c2) { create :level, :one, course: course_2 }

  let!(:team_old_user_c1) { create :team, level: level_1_c1 }
  let!(:team_old_user_c2) { create :team, level: level_2_c2 }
  let!(:student_old_user_c1) do
    create :student, user: old_user, startup: team_old_user_c1
  end
  let!(:student_old_user_c2) do
    create :student, user: old_user, startup: team_old_user_c2
  end

  # Add coach profiles
  let!(:coach_old_user) { create :faculty, school: school, user: old_user }
  let!(:course_enrollment) do
    create :faculty_course_enrollment, course: course_1, faculty: coach_old_user
  end
  let!(:team_in_c1) { create :team, level: level_1_c1 }
  let!(:student_in_c1) { create :student, startup: team_in_c1 }
  let!(:student_enrollment) do
    create :faculty_startup_enrollment,
           startup: team_in_c1,
           faculty: coach_old_user
  end

  # Add school admin
  let!(:school_admin) { create :school_admin, school: school, user: old_user }

  # Add a course author
  let!(:course_author) do
    create :course_author, user: old_user, course: course_1
  end

  # Add community data
  let!(:topic_1_new_user) { create :topic, :with_first_post, creator: new_user }
  let!(:topic_1_old_user) { create :topic, :with_first_post, creator: old_user }
  let!(:topic_subscription_old_user) do
    create :topic_subscription, topic: topic_1_old_user, user: old_user
  end
  let!(:post_old_user) do
    create :post, topic: topic_1_new_user, creator: old_user, post_number: 2
  end
  let!(:post_like_old_user) do
    create :post_like, post: post_old_user, user: old_user
  end

  # Add a coach note
  let!(:coach_note_old_user) do
    create :coach_note, author: old_user, student: student_in_c1
  end

  # Add a markdown attachment
  let!(:markdown_attachment) { create :markdown_attachment, user: old_user }

  # Course export
  let!(:course_export) do
    create :course_export, :students, user: old_user, course: course_2
  end

  describe '#execute' do
    it 'create initializes a school with a new course, coach, student and community' do
      old_user_id = old_user.id

      subject.new(old_user, new_user).execute

      # Check student profiles
      expect(student_old_user_c1.reload.user).to eq(new_user)
      expect(student_old_user_c2.reload.user).to eq(new_user)

      # Check coach enrollments
      expect(student_enrollment.reload.faculty.user).to eq(new_user)
      expect(course_enrollment.reload.faculty.user).to eq(new_user)

      # Check community data
      expect(topic_1_old_user.reload.creator).to eq(new_user)
      expect(topic_subscription_old_user.reload.user).to eq(new_user)
      expect(post_old_user.reload.creator).to eq(new_user)
      expect(post_like_old_user.reload.user).to eq(new_user)

      # Check coach notes
      expect(coach_note_old_user.reload.author).to eq(new_user)

      # Check markdown attachment
      expect(markdown_attachment.reload.user).to eq(new_user)

      # Check course exports created
      expect(course_export.reload.user).to eq(new_user)

      # Check admin rights
      expect(school_admin.reload.user).to eq(new_user)

      # Check course author
      expect(course_author.reload.user).to eq(new_user)

      # Check old user is deleted
      expect(User.find_by(id: old_user_id)).to eq(nil)
    end

    context 'both users have student profiles in the same course' do
      let!(:team_new_user_c1) { create :team, level: level_1_c1 }
      let!(:student_new_user_c1) do
        create :student, user: new_user, startup: team_new_user_c1
      end
      it 'prompts to select the student profile to be used' do
        expect { subject.new(old_user, new_user).execute }.to raise_error(
          RuntimeError,
          "Both users have student profiles in courses with ids: #{[course_1.id]}. Select one student profile for these courses, and pass the IDs of the selected student profiles as an array to student_profile_ids"
        )
      end

      it 'throws an error if both profile ids are passed to the service' do
        expect {
          subject.new(
            old_user,
            new_user,
            student_profile_ids: [
              student_new_user_c1.id,
              student_old_user_c1.id
            ]
          ).execute
        }.to raise_error(
          RuntimeError,
          "Only one student profile IDs must be supplied for course: #{course_1.id}"
        )
      end

      it 'retains the student profile of the new account if selected' do
        subject.new(
          old_user,
          new_user,
          student_profile_ids: [student_new_user_c1.id]
        ).execute

        student_profiles_for_c1 =
          new_user
            .reload
            .founders
            .joins(:course)
            .where(courses: { id: course_1.id })
        current_student_profile = student_profiles_for_c1.first
        expect(student_profiles_for_c1.count).to eq(1)
        expect(current_student_profile).to eq(student_new_user_c1)
      end

      it 'switches to the student profile of the old account if selected' do
        new_user_student_profile_id = student_new_user_c1.id
        subject.new(
          old_user,
          new_user,
          student_profile_ids: [student_old_user_c1.id]
        ).execute

        student_profiles_for_c1 =
          new_user
            .reload
            .founders
            .joins(:course)
            .where(courses: { id: course_1.id })
        current_student_profile = student_profiles_for_c1.first
        expect(student_profiles_for_c1.count).to eq(1)
        expect(current_student_profile).to eq(student_old_user_c1)
        expect(Founder.find_by(id: new_user_student_profile_id)).to eq(nil)
      end
    end
  end
end
