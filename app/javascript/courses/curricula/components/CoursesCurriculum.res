%bs.raw(`require("./CoursesCurriculum.css")`)

@bs.module external levelLockedImage: string = "../images/level-lock.svg"
@bs.module external levelEmptyImage: string = "../images/level-empty.svg"

open CoursesCurriculum__Types

let str = React.string
let t = I18n.t(~scope="components.CoursesCurriculum")

type state = {
  selectedLevelId: string,
  showLevelZero: bool,
  latestSubmissions: array<LatestSubmission.t>,
  statusOfTargets: array<TargetStatus.t>,
  notice: Notice.t,
  levelUpEligibility: LevelUpEligibility.t,
}

let targetStatusClasses = targetStatus => {
  let statusClasses =
    "curriculum__target-status--" ++ (targetStatus |> TargetStatus.statusClassesSufix)
  "curriculum__target-status px-3 py-px ml-4 h-6 " ++ statusClasses
}

let rendertarget = (target, statusOfTargets, author, courseId) => {
  let targetId = target |> Target.id
  let targetStatus =
    statusOfTargets |> ArrayUtils.unsafeFind(
      ts => ts |> TargetStatus.targetId == targetId,
      "Could not find targetStatus for listed target with ID " ++ targetId,
    )

  <div
    key={"target-" ++ targetId}
    className="courses-curriculum__target-container transition duration-200 bg-white hover:bg-lightBlue px-8">
    <div className="courses-curriculum__inner-container border-b flex">
    <Link
      href={"/targets/" ++ targetId}
      className="p-6 flex flex-grow items-center justify-between text-siliconBlue-900 cursor-pointer"
      ariaLabel={"Select Target " ++ targetId}>
      <span className="text-left leading-snug"> {Target.title(target)->str} </span>
      {ReactUtils.nullIf(
        <span className={targetStatusClasses(targetStatus)}>
          {TargetStatus.statusToString(targetStatus)->str}
        </span>,
        TargetStatus.isPending(targetStatus),
      )}
    </Link>
    {ReactUtils.nullUnless(
      <a
        title={t("edit_target_button_title", ~variables=[("title", Target.title(target))])}
        href={"/school/courses/" ++ courseId ++ "/targets/" ++ targetId ++ "/content"}
        className="hidden lg:block  text-gray-400 border-l border-transparent py-6 px-3 hover:text-siliconBlue-900 hover:bg-gray-200">
        <i className="fas fa-pencil-alt" />
      </a>,
      author,
    )}
    </div>
  </div>
}

let renderTargetGroup = (targetGroup, targets, statusOfTargets, author, courseId) => {
  let targetGroupId = targetGroup |> TargetGroup.id
  let targets = targets |> Js.Array.filter(t => t |> Target.targetGroupId == targetGroupId)

  <div
    key={"target-group-" ++ targetGroupId}
    className="curriculum__target-group-container relative mt-5 px-3">
    <div
      className="curriculum__target-group max-w-6xl mx-auto bg-white text-center relative z-10">
      {targetGroup |> TargetGroup.milestone
        ? <div
            className="inline-block px-3 py-2 bg-orange-400 font-bold text-xs rounded-b-lg leading-tight text-white uppercase">
            {t("milestone_targets") |> str}
          </div>
        : React.null}
      <div className="shadow-md rounded-lg overflow-hidden">
        <div className="p-6 pt-5 bg-lightGray">
          <div className="text-2xl font-bold leading-snug text-siliconBlue-900 ">
            {TargetGroup.name(targetGroup)->str}
          </div>
          <MarkdownBlock
            className="text-sm max-w-md mx-auto leading-snug text-siliconBlue-900 "
            markdown={TargetGroup.description(targetGroup)}
            profile=Markdown.AreaOfText
          />
        </div>
        {targets
        |> ArrayUtils.copyAndSort((t1, t2) => (t1 |> Target.sortIndex) - (t2 |> Target.sortIndex))
        |> Js.Array.map(target => rendertarget(target, statusOfTargets, author, courseId))
        |> React.array}
      </div>
    </div>
  </div>
}

let addSubmission = (setState, latestSubmission, levelUpEligibility) => setState(state => {
    let withoutSubmissionForThisTarget =
      state.latestSubmissions |> Js.Array.filter(s =>
        s |> LatestSubmission.targetId != (latestSubmission |> LatestSubmission.targetId)
      )

    let eligibility = Belt.Option.getWithDefault(levelUpEligibility, state.levelUpEligibility)

    {
      ...state,
      latestSubmissions: Js.Array.concat([latestSubmission], withoutSubmissionForThisTarget),
      levelUpEligibility: eligibility,
    }
  })

let handleLockedLevel = level =>
  <div className="max-w-xl mx-auto text-center mt-4">
    <div className="text-2xl font-bold px-3"> {t("level_locked") |> str} </div>
    <img className="max-w-sm mx-auto" src=levelLockedImage />
    {switch level |> Level.unlockAt {
    | Some(date) =>
      let dateString = date->DateFns.format("MMMM d, yyyy")
      <div className="font-semibold text-md px-3">
        <p> {t("level_locked_notice")->str} </p>
        <p> {t("level_locked_explanation", ~variables=[("date", dateString)])->str} </p>
      </div>
    | None => React.null
    }}
  </div>

let statusOfMilestoneTargets = (targetGroups, targets, level, statusOfTargets) => {
  let targetGroupsInLevel =
    targetGroups |> Js.Array.filter(tg => tg |> TargetGroup.levelId == (level |> Level.id))
  let milestoneTargetGroupIds =
    targetGroupsInLevel
    |> Js.Array.filter(tg => tg |> TargetGroup.milestone)
    |> Js.Array.map(tg => tg |> TargetGroup.id)

  let milestoneTargetIds =
    targets
    |> Js.Array.filter(t => milestoneTargetGroupIds |> Js.Array.includes(Target.targetGroupId(t)))
    |> Js.Array.map(t => t |> Target.id)

  statusOfTargets |> Js.Array.filter(ts =>
    milestoneTargetIds |> Js.Array.includes(TargetStatus.targetId(ts))
  )
}

let issuedCertificate = course =>
  switch Course.certificateSerialNumber(course) {
  | Some(csn) =>
    <div
      className="max-w-3xl mx-auto text-center mt-4 bg-white lg:rounded-lg shadow-md px-6 pt-6 pb-8">
      <div className="max-w-xl font-bold text-xl mx-auto mt-2 leading-tighttext-siliconBlue-900">
        {t("issued_certificate_heading")->str}
      </div>
      <a href={"/c/" ++ csn} className="mt-4 mb-2 btn btn-primary">
        <FaIcon classes="fas fa-certificate" />
        <span className="ml-2"> {t("issued_certificate_button")->str} </span>
      </a>
    </div>
  | None => React.null
  }

let computeLevelUp = (
  levelUpEligibility,
  course,
  teamLevel,
  targetGroups,
  targets,
  statusOfTargets,
) => {
  let progressionBehavior = course |> Course.progressionBehavior
  let currentLevelNumber = teamLevel |> Level.number

  let statusOfCurrentMilestoneTargets = statusOfMilestoneTargets(
    targetGroups,
    targets,
    teamLevel,
    statusOfTargets,
  )

  switch levelUpEligibility {
  | LevelUpEligibility.Eligible => Notice.LevelUp
  | AtMaxLevel =>
    TargetStatus.allComplete(statusOfCurrentMilestoneTargets) ? CourseComplete : Nothing
  | NoMilestonesInLevel => Nothing
  | CurrentLevelIncomplete =>
    switch progressionBehavior {
    | #Strict =>
      let currentLevelAttempted = TargetStatus.allAttempted(statusOfCurrentMilestoneTargets)

      if currentLevelAttempted {
        let hasRejectedSubmissions = TargetStatus.anyRejected(statusOfCurrentMilestoneTargets)
        LevelUpBlocked(currentLevelNumber, hasRejectedSubmissions)
      } else {
        Nothing
      }
    | #Unlimited => Nothing
    | #Limited(_progressionLimit) => Nothing
    }
  | PreviousLevelIncomplete =>
    switch progressionBehavior {
    | #Strict
    | #Unlimited =>
      Nothing
    | #Limited(progressionLimit) =>
      let minimumLevelNumber = currentLevelNumber - progressionLimit

      if minimumLevelNumber >= 1 {
        LevelUpLimited(currentLevelNumber, minimumLevelNumber)
      } else {
        Nothing
      }
    }
  | TeamMembersPending => TeamMembersPending
  | DateLocked => Nothing
  }
}

let computeNotice = (
  teamLevel,
  targetGroups,
  targets,
  statusOfTargets,
  course,
  team,
  preview,
  levelUpEligibility,
) =>
  if preview {
    Notice.Preview
  } else if Course.hasEnded(course) {
    CourseEnded
  } else if Team.accessEnded(team) {
    AccessEnded
  } else {
    computeLevelUp(levelUpEligibility, course, teamLevel, targetGroups, targets, statusOfTargets)
  }

let navigationLink = (direction, level, setState) => {
  let (leftIcon, longText, shortText, rightIcon, cssClass) = switch direction {
  | #Previous => (Some("fa-arrow-left"), t("nav_previous_level"), "Previous", None, "btn-primary-ghost ")
  | #Next => (None, t("nav_next_level"), "Next", Some("fa-arrow-right"), "btn-primary ml-auto")
  }

  let arrow = icon =>
    icon->Belt.Option.mapWithDefault(React.null, icon => <FaIcon classes={"fas " ++ icon} />)

  <button
    onClick={_ => setState(state => {...state, selectedLevelId: level |> Level.id})}
    className={cssClass}>
    {arrow(leftIcon)}
    <span className="mx-2 hidden md:inline"> {longText |> str} </span>
    <span className="mx-2 inline md:hidden"> {shortText |> str} </span>
    {arrow(rightIcon)}
  </button>
}

let quickNavigationLinks = (levels, selectedLevel, setState) => {
  let previous = selectedLevel |> Level.previous(levels)
  let next = selectedLevel |> Level.next(levels)

  <div key="quick-navigation-links">
    <hr className="my-6" />
    <div className="container mx-auto max-w-6xl flex justify-between px-3 lg:px-0">
      {switch (previous, next) {
      | (Some(previousLevel), Some(nextLevel)) =>
        [
          <div key="previous">
            {navigationLink(#Previous, previousLevel, setState)}
          </div>,
          <div key="next">
            {navigationLink(#Next, nextLevel, setState)}
          </div>,
        ] |> React.array

      | (Some(previousUrl), None) =>
         {navigationLink(#Previous, previousUrl, setState)}
      | (None, Some(nextUrl)) =>
         {navigationLink(#Next, nextUrl, setState)}
      | (None, None) => React.null
      }}
    </div>
  </div>
}

@react.component
let make = (
  ~author,
  ~course,
  ~levels,
  ~targetGroups,
  ~targets,
  ~submissions,
  ~team,
  ~coaches,
  ~users,
  ~evaluationCriteria,
  ~preview,
  ~accessLockedLevels,
  ~levelUpEligibility,
) => {
  let url = RescriptReactRouter.useUrl()

  let selectedTarget = switch url.path {
  | list{"targets", targetId, ..._} =>
    targetId
    ->StringUtils.paramToId
    ->Belt.Option.map(targetId =>
      targets |> ArrayUtils.unsafeFind(
        t => t |> Target.id == targetId,
        "Could not find selectedTarget with ID " ++ targetId,
      )
    )
  | _ => None
  }

  /* Level selection is a bit complicated because of how the selector for L0 is
   * separate from the other levels. selectedLevelId is the numbered level
   * selected by the user, whereas showLevelZero is the toggle on the title of
   * L0 determining whether the user has picked it or not - it'll show up only
   * if L0 is available, and will override the selectedLevelId. This rule is
   * used to determine currentLevelId, which is the actual level whose contents
   * are shown on the page. */

  let levelZero = levels |> Js.Array.find(l => l |> Level.number == 0)
  let teamLevelId = team |> Team.levelId

  let teamLevel =
    levels |> ArrayUtils.unsafeFind(
      l => l |> Level.id == teamLevelId,
      "Could not find teamLevel with ID " ++ teamLevelId,
    )

  let targetLevelId = switch selectedTarget {
  | Some(target) =>
    let targetGroupId = target |> Target.targetGroupId

    let targetGroup =
      targetGroups |> ArrayUtils.unsafeFind(
        t => t |> TargetGroup.id == targetGroupId,
        "Could not find targetGroup with ID " ++ targetGroupId,
      )

    Some(targetGroup |> TargetGroup.levelId)
  | None => None
  }

  /* Curried function so that this can be re-used when a new submission is created. */
  let computeTargetStatus = TargetStatus.compute(
    preview,
    team,
    course,
    levels,
    targetGroups,
    targets,
  )

  let initialRender = React.useRef(true)

  let (state, setState) = React.useState(() => {
    let statusOfTargets = computeTargetStatus(submissions)

    {
      selectedLevelId: switch (preview, targetLevelId, levelZero) {
      | (true, None, None) => Level.first(levels) |> Level.id
      | (_, Some(targetLevelId), Some(levelZero)) =>
        levelZero |> Level.id == targetLevelId ? teamLevelId : targetLevelId
      | (_, Some(targetLevelId), None) => targetLevelId
      | (_, None, _) => teamLevelId
      },
      showLevelZero: switch (levelZero, targetLevelId) {
      | (Some(levelZero), Some(targetLevelId)) => levelZero |> Level.id == targetLevelId
      | (Some(_), None)
      | (None, Some(_))
      | (None, None) => false
      },
      latestSubmissions: submissions,
      statusOfTargets: statusOfTargets,
      notice: computeNotice(
        teamLevel,
        targetGroups,
        targets,
        statusOfTargets,
        course,
        team,
        preview,
        levelUpEligibility,
      ),
      levelUpEligibility: levelUpEligibility,
    }
  })

  let currentLevelId = switch (levelZero, state.showLevelZero) {
  | (Some(levelZero), true) => levelZero |> Level.id
  | (Some(_), false)
  | (None, true | false) =>
    state.selectedLevelId
  }

  let currentLevel =
    levels |> ArrayUtils.unsafeFind(
      l => l |> Level.id == currentLevelId,
      "Could not find currentLevel with id " ++ currentLevelId,
    )

  let selectedLevel =
    levels |> ArrayUtils.unsafeFind(
      l => l |> Level.id == state.selectedLevelId,
      "Could not find selectedLevel with id " ++ state.selectedLevelId,
    )

  React.useEffect1(() => {
    if initialRender.current {
      initialRender.current = false
    } else {
      let newStatusOfTargets = computeTargetStatus(state.latestSubmissions)

      setState(state => {
        ...state,
        statusOfTargets: newStatusOfTargets,
        notice: computeNotice(
          teamLevel,
          targetGroups,
          targets,
          newStatusOfTargets,
          course,
          team,
          preview,
          state.levelUpEligibility,
        ),
      })
    }
    None
  }, [state.latestSubmissions])

  let targetGroupsInLevel =
    targetGroups |> Js.Array.filter(tg => tg |> TargetGroup.levelId == currentLevelId)

  <div className="bg-white pt-11 pb-8">
    {switch selectedTarget {
    | Some(target) =>
      let targetStatus =
        state.statusOfTargets |> ArrayUtils.unsafeFind(
          ts => ts |> TargetStatus.targetId == (target |> Target.id),
          "Could not find targetStatus for selectedTarget with ID " ++ (target |> Target.id),
        )

      <CoursesCurriculum__Overlay
        target
        course
        targetStatus
        addSubmissionCB={addSubmission(setState)}
        targets
        statusOfTargets=state.statusOfTargets
        users
        evaluationCriteria
        coaches
        preview
        author
      />

    | None => React.null
    }}
    {issuedCertificate(course)}
    <CoursesCurriculum__NoticeManager notice=state.notice course />
    {switch state.notice {
    | LevelUp => React.null
    | _anyOtherNotice =>
      [
        <div className="relative" key="curriculum-body">
          <CoursesCurriculum__LevelSelector
            levels
            teamLevel
            selectedLevel
            setSelectedLevelId={selectedLevelId =>
              setState(state => {...state, selectedLevelId: selectedLevelId})}
            showLevelZero=state.showLevelZero
            setShowLevelZero={showLevelZero =>
              setState(state => {...state, showLevelZero: showLevelZero})}
            levelZero
          />
          {ReactUtils.nullUnless(
            <div className="text-center mt-2 max-w-3xl mx-auto">
              <a
                className="btn btn-primary-ghost btn-small"
                href={"/school/courses/" ++
                Course.id(course) ++
                "/curriculum?level=" ++
                Level.number(currentLevel)->string_of_int}>
                <i className="fas fa-pencil-alt" />
                <span className="ml-2"> {t("edit_level_button")->str} </span>
              </a>
            </div>,
            author,
          )}
          {currentLevel |> Level.isLocked && accessLockedLevels
            ? <div
                className="text-center p-3 mt-5 border rounded-lg bg-blue-100 max-w-3xl mx-auto"
                dangerouslySetInnerHTML={
                  "__html": t(
                    "level_locked_for_students_notice",
                    ~variables=[("date", Level.unlockDateString(currentLevel))],
                  ),
                }
              />
            : React.null}
          {Level.isUnlocked(currentLevel) || accessLockedLevels
            ? targetGroupsInLevel == []
                ? <div className="mx-auto py-10">
                    <img className="max-w-xs md:max-w-sm mx-auto" src=levelEmptyImage />
                    <p className="text-center font-semibold text-lg mt-4">
                      {t("empty_level_content_notice") |> str}
                    </p>
                  </div>
                : targetGroupsInLevel
                  |> TargetGroup.sort
                  |> Js.Array.map(targetGroup =>
                    renderTargetGroup(
                      targetGroup,
                      targets,
                      state.statusOfTargets,
                      author,
                      Course.id(course),
                    )
                  )
                  |> React.array
            : handleLockedLevel(currentLevel)}
        </div>,
        {state.showLevelZero ? React.null : quickNavigationLinks(levels, selectedLevel, setState)},
      ] |> React.array
    }}
  </div>
}
