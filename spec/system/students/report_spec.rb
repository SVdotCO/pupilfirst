require 'rails_helper'

feature "Course students report", js: true do
  include UserSpecHelper
  include MarkdownEditorHelper
  include NotificationHelper

  # The basics
  let!(:school) { create :school, :current }
  let(:course) { create :course, school: school }
  let(:level_1) { create :level, :one, course: course }
  let(:level_2) { create :level, :two, course: course }
  let(:level_3) { create :level, :three, course: course }
  let(:course_coach) { create :faculty, school: school }
  let(:team_coach) { create :faculty, school: school }
  let(:coach_without_access) { create :faculty, school: school }

  # Create few teams
  let!(:team) { create :startup, level: level_3 }

  # Create few targets for the student
  let(:target_group_l1) { create :target_group, level: level_1, milestone: true }
  let(:target_group_l2) { create :target_group, level: level_2, milestone: true }
  let(:target_group_l3) { create :target_group, level: level_3, milestone: true }

  let(:target_l1) { create :target, :for_founders, target_group: target_group_l1 }
  let(:target_l2) { create :target, :for_founders, target_group: target_group_l2 }
  let(:target_l3) { create :target, :for_founders, target_group: target_group_l3 }
  let!(:target_4) { create :target, :for_founders, target_group: target_group_l3 }
  let(:quiz_target_1) { create :target, :for_founders, target_group: target_group_l1 }
  let(:quiz_target_2) { create :target, :for_founders, target_group: target_group_l3 }

  # Create evaluation criteria for targets
  let(:evaluation_criterion_1) { create :evaluation_criterion, course: course }
  let(:evaluation_criterion_2) { create :evaluation_criterion, course: course }

  # Create submissions for relevant targets
  let(:submission_target_l1_1) { create(:timeline_event, latest: true, target: target_l1, evaluator_id: course_coach.id, evaluated_at: 2.days.ago, passed_at: 3.days.ago) }
  let(:submission_target_l1_2) { create(:timeline_event, latest: false, target: target_l2, evaluator_id: course_coach.id, evaluated_at: 3.days.ago, passed_at: nil) }
  let(:submission_target_l2) { create(:timeline_event, latest: true, target: target_l2, evaluator_id: course_coach.id, evaluated_at: 1.day.ago, passed_at: 1.day.ago) }
  let(:submission_target_l3) { create(:timeline_event, latest: true, target: target_l3, evaluator_id: course_coach.id, evaluated_at: 1.day.ago, passed_at: 1.day.ago) }
  let(:submission_quiz_target_1) { create(:timeline_event, latest: true, target: quiz_target_1, passed_at: 1.day.ago, quiz_score: '1/3') }
  let(:submission_quiz_target_2) { create(:timeline_event, latest: true, target: quiz_target_2, passed_at: 1.day.ago, quiz_score: '3/5') }

  before do
    create :faculty_course_enrollment, faculty: course_coach, course: course
    create :faculty_startup_enrollment, faculty: team_coach, startup: team

    target_l1.evaluation_criteria << evaluation_criterion_1
    target_l2.evaluation_criteria << [evaluation_criterion_1, evaluation_criterion_2]
    target_l3.evaluation_criteria << evaluation_criterion_2
    target_4.evaluation_criteria << evaluation_criterion_2

    submission_target_l1_1.founders << team.founders.first
    submission_target_l1_2.founders << team.founders.first
    submission_target_l2.founders << team.founders.first
    submission_target_l3.founders << team.founders.first
    submission_quiz_target_1.founders << team.founders.first
    submission_quiz_target_2.founders << team.founders.first

    submission_target_l1_2.timeline_event_grades.create!(evaluation_criterion: evaluation_criterion_1, grade: 1)
    submission_target_l1_1.timeline_event_grades.create!(evaluation_criterion: evaluation_criterion_1, grade: 2)

    submission_target_l2.timeline_event_grades.create!(evaluation_criterion: evaluation_criterion_1, grade: 2)
    submission_target_l2.timeline_event_grades.create!(evaluation_criterion: evaluation_criterion_2, grade: 2)
    submission_target_l3.timeline_event_grades.create!(evaluation_criterion: evaluation_criterion_2, grade: 2)
  end

  scenario 'coach opens the student report, checks performance and makes notes' do
    sign_in_user course_coach.user, referer: students_course_path(course)

    expect(page).to have_text(team.name)
    founder = team.founders.first

    find("div[aria-label='student-card-#{founder.id}']").click
    expect(page).to have_text(founder.name)
    expect(page).to have_text('Level Progress')
    expect(page).to have_selector('.student-overlay__student-level', count: course.levels.where.not(number: 0).count)

    # Targets Overview
    expect(page).to have_text('Targets Overview')

    within("div[aria-label='target-completion-status']") do
      expect(page).to have_content('Total Targets Completed')
      expect(page).to have_content('83%')
      expect(page).to have_content('5/6 Targets')
    end

    within("div[aria-label='quiz-performance-chart']") do
      expect(page).to have_content('Average Quiz Score')
      expect(page).to have_content('46%')
      expect(page).to have_content('2 Quizzes Attempted')
    end

    # Average Grades
    expect(page).to have_text('Average Grades')
    within("div[aria-label='average-grade-for-criterion-#{evaluation_criterion_1.id}']") do
      expect(page).to have_content(evaluation_criterion_1.name)
      expect(page).to have_content('1.7/3')
    end

    within("div[aria-label='average-grade-for-criterion-#{evaluation_criterion_2.id}']") do
      expect(page).to have_content(evaluation_criterion_2.name)
      expect(page).to have_content('2/3')
    end

    # Check submissions of student
    find('li', text: 'Submissions').click
    expect(page).to have_content(target_l1.title)
    expect(page).to_not have_content(target_4.title)
    within("div[aria-label='student-submission-card-#{submission_target_l1_2.id}']") do
      expect(page).to have_content('Failed')
    end

    within("div[aria-label='student-submissions']") do
      expect(page).to have_link(href: "/submissions/#{submission_target_l1_1.id}")
      expect(page).to have_link(href: "/submissions/#{submission_target_l3.id}")
    end

    # Add few notes
    find('li', text: 'Notes').click
    expect(page).to have_text('No notes here!')
    note_1 = Faker::Markdown.sandwich(2)
    note_2 = Faker::Markdown.sandwich(2)
    add_markdown(note_1)
    click_button('Save Note')
    dismiss_notification
    expect(page).to have_text(course_coach.name)
    expect(page).to have_text(course_coach.title)
    expect(CoachNote.where(student: founder).last.note).to eq(note_1)

    add_markdown(note_2)
    click_button('Save Note')
    dismiss_notification
    expect(page).to have_text(course_coach.name, count: 2)
    expect(page).to have_text(course_coach.title, count: 2)
    expect(page).to have_text(Date.today.strftime('%B %-d'), count: 2)
    expect(CoachNote.where(student: founder).last.note).to eq(note_2)
  end

  scenario 'coach loads more submissions' do
    # Create over 20 reviewed submissions
    founder = team.founders.first
    20.times do
      submission = TimelineEvent.create!(description: Faker::Lorem.sentence, latest: true, target: target_4, evaluator_id: course_coach.id, evaluated_at: 2.days.ago, passed_at: 3.days.ago)
      submission.founders << founder
      submission.timeline_event_grades.create!(evaluation_criterion: evaluation_criterion_2, grade: 2)
    end

    sign_in_user course_coach.user, referer: student_report_path(founder)
    expect(page).to have_text(founder.name)
    find('li', text: 'Submissions').click
    expect(page).to have_button('Load More...')
    click_button('Load More...')

    within("div[aria-label='student-submissions']") do
      expect(page).to have_selector('a', count: founder.timeline_events.evaluated_by_faculty.count)
    end

    # Switching tabs should preserve already loaded submissions
    find('li', text: 'Notes').click
    find('li', text: 'Submissions').click

    within("div[aria-label='student-submissions']") do
      expect(page).to have_selector('a', count: founder.timeline_events.evaluated_by_faculty.count)
    end
  end

  scenario 'team coach accesses student report' do
    founder = team.founders.first
    sign_in_user team_coach.user, referer: student_report_path(founder)

    # Check a student parameter
    within("div[aria-label='target-completion-status']") do
      expect(page).to have_content('Total Targets Completed')
      expect(page).to have_content('83%')
      expect(page).to have_content('5/6 Targets')
    end

    # Check submissions
    find('li', text: 'Submissions').click
    expect(page).to have_content(target_l1.title)
    expect(page).to_not have_content(target_4.title)
    within("div[aria-label='student-submission-card-#{submission_target_l1_2.id}']") do
      expect(page).to have_content('Failed')
    end

    # Add a note
    find('li', text: 'Notes').click
    expect(page).to have_text('No notes here!')
    note = Faker::Markdown.sandwich(2)
    add_markdown(note)
    click_button('Save Note')
    dismiss_notification
    expect(page).to have_text(team_coach.name)
    expect(page).to have_text(team_coach.title)
    expect(CoachNote.where(student: founder).last.note).to eq(note)
  end

  scenario 'unauthorized coach attempts to access student report' do
    founder = team.founders.first
    sign_in_user coach_without_access.user, referer: student_report_path(founder)
    expect(page).to have_content("The page you were looking for doesn't exist")
  end
end
