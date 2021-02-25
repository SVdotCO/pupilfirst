open CourseApplicants__Types

let t = I18n.t(~scope="components.CourseApplicants__Root")

let str = React.string

// type teamId = string

// type tags = array<string>

// type formVisible =
//   | None
//   | CreateForm
//   | UpdateForm(Student.t, teamId)

// type state = {
//   pagedTeams: Page.t,
//   filter: Filter.t,
//   selectedStudents: array<SelectedStudent.t>,
//   formVisible: formVisible,
//   tags: tags,
//   loading: Loading.t,
//   refreshTeams: bool,
// }

// type action =
//   | SelectStudent(SelectedStudent.t)
//   | DeselectStudent(string)
//   | UpdateFormVisible(formVisible)
//   | UpdateStudentCertification(Student.t, Team.t)
//   | UpdateTeams(Page.t)
//   | UpdateFilter(Filter.t)
//   | RefreshData(tags)
//   | UpdateTeam(Team.t, tags)
//   | SetLoading(Loading.t)

// let handleTeamUpResponse = (send, _json) => {
//   send(RefreshData([]))
//   Notification.success("Success!", "Teams updated successfully")
// }

// let handleErrorCB = () => ()

// let addTags = (oldtags, newTags) =>
//   oldtags |> Array.append(newTags) |> ArrayUtils.sort_uniq(String.compare)

// let teamUp = (selectedStudents, responseCB) => {
//   let studentIds = selectedStudents |> Array.map(s => s |> SelectedStudent.id)
//   let payload = Js.Dict.empty()
//   Js.Dict.set(payload, "authenticity_token", AuthenticityToken.fromHead() |> Js.Json.string)
//   Js.Dict.set(
//     payload,
//     "founder_ids",
//     studentIds |> {
//       open Json.Encode
//       array(string)
//     },
//   )
//   let url = "/school/students/team_up"
//   Api.create(url, payload, responseCB, handleErrorCB)
// }

// let initialState = tags => {
//   pagedTeams: Unloaded,
//   selectedStudents: [],
//   filter: Filter.make(),
//   formVisible: None,
//   tags: tags,
//   loading: Loading.NotLoading,
//   refreshTeams: false,
// }

// let reducer = (state, action) =>
//   switch action {
//   | SelectStudent(selectedStudent) => {
//       ...state,
//       selectedStudents: state.selectedStudents |> Array.append([selectedStudent]),
//     }

//   | DeselectStudent(id) => {
//       ...state,
//       selectedStudents: state.selectedStudents |> Js.Array.filter(s =>
//         s |> SelectedStudent.id != id
//       ),
//     }

//   | UpdateFormVisible(formVisible) => {...state, formVisible: formVisible}
//   | UpdateTeams(pagedTeams) => {
//       ...state,
//       pagedTeams: pagedTeams,
//       loading: Loading.NotLoading,
//     }
//   | UpdateFilter(filter) => {
//       ...state,
//       filter: filter,
//       refreshTeams: !state.refreshTeams,
//     }
//   | RefreshData(tags) => {
//       ...state,
//       refreshTeams: !state.refreshTeams,
//       tags: addTags(state.tags, tags),
//       formVisible: None,
//       selectedStudents: [],
//     }
//   | UpdateTeam(team, tags) => {
//       ...state,
//       pagedTeams: state.pagedTeams |> Page.updateTeam(team),
//       tags: addTags(state.tags, tags),
//       formVisible: None,
//       selectedStudents: [],
//     }
//   | SetLoading(loading) => {...state, loading: loading}
//   | UpdateStudentCertification(updatedStudent, team) =>
//     let updatedTeam = Team.updateStudent(team, updatedStudent)
//     let pagedTeams = Page.updateTeam(updatedTeam, state.pagedTeams)
//     let teamId = Team.id(team)
//     {...state, pagedTeams: pagedTeams, formVisible: UpdateForm(updatedStudent, teamId)}
//   }

// let selectStudent = (send, student, team) => {
//   let selectedStudent = SelectedStudent.make(
//     ~name=student |> Student.name,
//     ~id=student |> Student.id,
//     ~teamId=team |> Team.id,
//     ~avatarUrl=student.avatarUrl,
//     ~levelId=team |> Team.levelId,
//     ~teamSize=team |> Team.students |> Array.length,
//   )

//   send(SelectStudent(selectedStudent))
// }

// let deselectStudent = (send, studentId) => send(DeselectStudent(studentId))

// let updateFilter = (send, filter) => send(UpdateFilter(filter))

// module Sortable = {
//   type t = Filter.sortBy

//   let criterion = c =>
//     switch c {
//     | Filter.Name => t("sort_criterion_name")
//     | CreatedAt => t("sort_criterion_last_created")
//     | UpdatedAt => t("sort_criterion_last_updated")
//     }

//   let criterionType = c =>
//     switch c {
//     | Filter.Name => #String
//     | CreatedAt
//     | UpdatedAt =>
//       #Number
//     }
// }

// module StudentsSorter = Sorter.Make(Sortable)

// let studentsSorter = (send, filter) =>
//   <div className="ml-2 flex-shrink-0">
//     <label className="block text-tiny uppercase font-semibold">
//       {t("sort_criterion_label") |> str}
//     </label>
//     <div className="mt-1">
//       <StudentsSorter
//         criteria=[Filter.Name, CreatedAt, UpdatedAt]
//         selectedCriterion={Filter.sortBy(filter)}
//         direction={Filter.sortDirection(filter)}
//         onDirectionChange={sortDirection =>
//           updateFilter(send, {...filter, sortDirection: sortDirection})}
//         onCriterionChange={sortBy => updateFilter(send, {...filter, sortBy: sortBy})}
//       />
//     </div>
//   </div>

// let updateTeams = (send, pagedTeams) => send(UpdateTeams(pagedTeams))

// let showEditForm = (send, student, teamId) => send(UpdateFormVisible(UpdateForm(student, teamId)))

// let submitForm = (send, tagsToApply) => send(RefreshData(tagsToApply))

// let updateForm = (send, tagsToApply, team) =>
//   switch team {
//   | Some(t) => send(UpdateTeam(t, tagsToApply))
//   | None => send(RefreshData(tagsToApply))
//   }

// let reloadTeams = (send, ()) => send(RefreshData([]))

// let setLoading = (send, loading) => send(SetLoading(loading))

@react.component
let make = (~courseId, ~tags) => {
  // let (state, send) = React.useReducer(reducer, initialState(studentTags))

  <div className="flex flex-1 flex-col">
    // {switch state.formVisible {
    // | None => ReasonReact.null
    // | CreateForm =>
    //   <SchoolAdmin__EditorDrawer closeDrawerCB={() => send(UpdateFormVisible(None))}>
    //     <StudentsEditor__CreateForm courseId submitFormCB={submitForm(send)} teamTags=state.tags />
    //   </SchoolAdmin__EditorDrawer>

    // | UpdateForm(student, teamId) =>
    //   let team = teamId |> Team.unsafeFind(state.pagedTeams |> Page.teams, "Root")
    //   let courseCoaches =
    //     schoolCoaches |> Js.Array.filter(coach => courseCoachIds |> Array.mem(Coach.id(coach)))
    //   <SchoolAdmin__EditorDrawer closeDrawerCB={() => send(UpdateFormVisible(None))}>
    //     <StudentsEditor__UpdateForm
    //       student
    //       team
    //       teamTags=state.tags
    //       currentUserName
    //       courseCoaches
    //       certificates
    //       updateFormCB={updateForm(send)}
    //       reloadTeamsCB={reloadTeams(send)}
    //       updateStudentCertificationCB={updatedStudent =>
    //         send(UpdateStudentCertification(updatedStudent, team))}
    //     />
    //   </SchoolAdmin__EditorDrawer>
    // }}
    <div className="px-6 pb-4 flex-1 bg-gray-100 relative overflow-y-scroll">
      <div className="bg-gray-100 sticky top-0 py-3">
        <div className="border rounded-lg mx-auto max-w-3xl bg-white ">
          <div>
            <div className="flex w-full items-start p-4">
              {//   <StudentsEditor__Search
              //     filter=state.filter updateFilterCB={updateFilter(send)} tags=state.tags levels
              //   />
              //   {studentsSorter(send, state.filter)}
              "search"->str}
            </div>
          </div>
        </div>
      </div>
      <div> {"lsit"->str} </div>
    </div>
    // {
    //   let loading = switch state.pagedTeams {
    //   | Unloaded => false
    //   | _ =>
    //     switch state.loading {
    //     | NotLoading => false
    //     | Reloading => true
    //     | LoadingMore => false
    //     }
    //   }
    //   <LoadingSpinner loading />
    // }
  </div>
}