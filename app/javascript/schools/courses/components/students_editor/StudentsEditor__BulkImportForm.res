let str = React.string

open StudentsEditor__Types

let t = I18n.t(~scope="components.StudentsEditor__BulkImportForm")

module CSVData = {
  type t = StudentCSVData.t
}

module CSVReader = CSVReader.Make(CSVData)

type fileInvalid =
  | InvalidCSVFile
  | EmptyFile
  | InvalidTemplate
  | ExceededEntries
  | InvalidData(array<CSVDataError.t>)

type state = {
  fileInfo: option<CSVReader.fileInfo>,
  saving: bool,
  csvData: array<StudentCSVData.t>,
  fileInvalid: option<fileInvalid>,
}

let initialState = {
  fileInfo: None,
  saving: false,
  csvData: [],
  fileInvalid: None,
}

let validTemplate = csvData => {
  let firstRow = Js.Array.unsafe_get(csvData, 0)
  StudentCSVData.name(firstRow)->Belt.Option.isSome
}

let validateFile = (csvData, fileInfo) => {
  CSVReader.fileSize(fileInfo) > 100000 || CSVReader.fileType(fileInfo) != "text/csv"
    ? Some(InvalidCSVFile)
    : csvData |> ArrayUtils.isEmpty
    ? Some(EmptyFile)
    : !validTemplate(csvData)
    ? Some(InvalidTemplate)
    : Array.length(csvData) > 1000
    ? Some(ExceededEntries)
    : {
        let dataErrors = CSVDataError.parseError(csvData)
        dataErrors |> ArrayUtils.isNotEmpty ? Some(InvalidData(dataErrors)) : None
      }
}

type action =
  | UpdateFileInvalid(option<fileInvalid>)
  | LoadCSVData(array<StudentCSVData.t>, CSVReader.fileInfo)
  | ClearCSVData
  | BeginSaving
  | EndSaving
  | FailSaving

let fileInputText = (~fileInfo: option<CSVReader.fileInfo>) =>
  fileInfo->Belt.Option.mapWithDefault(t("csv_file_input_placeholder"), info => info.name)

let reducer = (state, action) =>
  switch action {
  | UpdateFileInvalid(fileInvalid) => {...state, fileInvalid: fileInvalid}
  | ClearCSVData => {...state, fileInfo: None, fileInvalid: None, csvData: []}
  | BeginSaving => {...state, saving: true}
  | FailSaving => {...state, saving: false}
  | EndSaving => initialState
  | LoadCSVData(csvData, fileInfo) => {
      ...state,
      csvData: csvData,
      fileInfo: Some(fileInfo),
      fileInvalid: validateFile(csvData, fileInfo),
    }
  }

let saveDisabled = state =>
  state.fileInfo->Belt.Option.isNone || state.fileInvalid->Belt.Option.isSome || state.saving

let submitForm = (courseId, send, event) => {
  ReactEvent.Form.preventDefault(event)
  send(BeginSaving)

  let formData =
    ReactEvent.Form.target(event)->DomUtils.EventTarget.unsafeToElement->DomUtils.FormData.create

  let url = "/school/courses/" ++ courseId ++ "/bulk_import_students"

  Api.sendFormData(
    url,
    formData,
    json => {
      Json.Decode.field("success", Json.Decode.bool, json)
        ? Notification.success(t("done_exclamation"), t("success_notification"))
        : ()
      send(EndSaving)
    },
    () => send(FailSaving),
  )
}

let tableHeader = {
  <thead>
    <tr className="bg-gray-300">
      <th className="w-12 border border-gray-400 text-left text-xs px-2 py-1 font-semibold" />
      <th className="border border-gray-400 text-left text-xs px-2 py-1 font-semibold">
        {"name" |> str}
      </th>
      <th className="border border-gray-400 text-left text-xs px-2 py-1 font-semibold">
        {"email" |> str}
      </th>
      <th className="border border-gray-400 text-left text-xs px-2 py-1 font-semibold">
        {"title" |> str}
      </th>
      <th className="border border-gray-400 text-left text-xs px-2 py-1 font-semibold">
        {"team_name" |> str}
      </th>
      <th className="border border-gray-400 text-left text-xs px-2 py-1 font-semibold">
        {"tags" |> str}
      </th>
      <th className="border border-gray-400 text-left text-xs px-2 py-1 font-semibold">
        {"affiliation" |> str}
      </th>
    </tr>
  </thead>
}

let tableRows = (csvData, ~startingRow=0, ()) => {
  csvData
  |> Array.mapi((index, studentData) =>
    <tr key={string_of_int(index)}>
      <td className="w-12 bg-gray-300 border border-gray-400 truncate text-xs px-2 py-1">
        {string_of_int(startingRow + index + 2) |> str}
      </td>
      <td className="border border-gray-400 truncate text-xs px-2 py-1">
        {StudentCSVData.name(studentData)->Belt.Option.getWithDefault("") |> str}
      </td>
      <td className="border border-gray-400 truncate text-xs px-2 py-1">
        {StudentCSVData.email(studentData)->Belt.Option.getWithDefault("") |> str}
      </td>
      <td className="border border-gray-400 truncate text-xs px-2 py-1">
        {StudentCSVData.title(studentData)->Belt.Option.getWithDefault("") |> str}
      </td>
      <td className="border border-gray-400 truncate text-xs px-2 py-1">
        {StudentCSVData.teamName(studentData)->Belt.Option.getWithDefault("") |> str}
      </td>
      <td className="border border-gray-400 truncate text-xs px-2 py-1">
        {StudentCSVData.tags(studentData)->Belt.Option.getWithDefault("") |> str}
      </td>
      <td className="border border-gray-400 truncate text-xs px-2 py-1">
        {StudentCSVData.affiliation(studentData)->Belt.Option.getWithDefault("") |> str}
      </td>
    </tr>
  )
  |> React.array
}

let truncatedTable = csvData => {
  let firsTwoRows = Js.Array.slice(~start=0, ~end_=2, csvData)
  let lastTwoRows = Js.Array.sliceFrom(Array.length(csvData) - 2, csvData)
  <div>
    <table className="table-fixed mt-2 border w-full overflow-x-scroll">
      {tableHeader} <tbody> {tableRows(firsTwoRows, ())} </tbody>
    </table>
    <table className="table-fixed relative w-full overflow-x-scroll">
      <tbody>
        <tr
          className="divide-x divide-dashed divide-gray-400 border-l border-r border-dashed border-gray-400">
          <td className="w-12 px-2 py-3" />
          <td className="px-2 py-3" />
          <td colSpan=3 className="px-2 py-3">
            <div>
              <div className="absolute inset-0 flex items-center" ariaHidden=true>
                <div className="w-full border-t border-b py-1 border-dashed border-gray-400" />
              </div>
              <div className="relative flex justify-center">
                <span className="px-2 bg-white text-xs italic text-center text-gray-700">
                  {("- - - " ++ string_of_int(Array.length(csvData) - 4) ++ " Rows - - -")->str}
                </span>
              </div>
            </div>
          </td>
          <td className="px-2 py-3" />
          <td className="px-2 py-3" />
        </tr>
      </tbody>
    </table>
    <table className="table-fixed border w-full overflow-x-scroll">
      <tbody> {tableRows(lastTwoRows, ~startingRow={Array.length(csvData) - 2}, ())} </tbody>
    </table>
  </div>
}

let csvDataTable = (csvData, fileInvalid) => {
  ReactUtils.nullIf(
    <div className="mt-4">
      <p
        className="flex items-center bg-green-200 text-green-800 font-semibold text-xs p-2 rounded">
        <PfIcon className="if i-check-regular if-fw mr-2" />
        <span> {t("valid_data_message") |> str} </span>
      </p>
      <p className="font-semibold text-xs mt-4"> {t("valid_data_summary_text") |> str} </p>
      {csvData |> Array.length <= 10
        ? <table className="table-fixed mt-2 border w-full overflow-x-scroll">
            {tableHeader} <tbody> {tableRows(csvData, ())} </tbody>
          </table>
        : truncatedTable(csvData)}
    </div>,
    fileInvalid->Belt.Option.isSome,
  )
}

let clearFile = send => {
  DomUtils.Element.clearFileInput(
    ~inputId="csv-file-input",
    ~callBack={() => send(ClearCSVData)},
    (),
  )
}

let errorsTable = (csvData, errors) => {
  <table className="table-fixed mt-4 border w-full overflow-x-scroll">
    {tableHeader} <tbody> {errors |> Array.mapi((index, error) => {
        let rowNumber = CSVDataError.rowNumber(error)
        let studentData = Js.Array2.unsafe_get(csvData, rowNumber - 2)
        <tr key={string_of_int(index)}>
          <td className="border border-gray-400 truncate text-xs px-2 py-1">
            {rowNumber |> string_of_int |> str}
          </td>
          <td
            className={"border border-gray-400 truncate text-xs px-2 py-1 " ++ (
              CSVDataError.hasNameError(error) ? "bg-red-200 text-red-800" : ""
            )}>
            {StudentCSVData.name(studentData)->Belt.Option.getWithDefault("") |> str}
          </td>
          <td
            className={"border border-gray-400 truncate text-xs px-2 py-1 " ++ (
              CSVDataError.hasEmailError(error) ? "bg-red-200 text-red-800" : ""
            )}>
            {StudentCSVData.email(studentData)->Belt.Option.getWithDefault("") |> str}
          </td>
          <td
            className={"border border-gray-400 truncate text-xs px-2 py-1 " ++ (
              CSVDataError.hasTitleError(error) ? "bg-red-200 text-red-800" : ""
            )}>
            {StudentCSVData.title(studentData)->Belt.Option.getWithDefault("") |> str}
          </td>
          <td
            className={"border border-gray-400 truncate text-xs px-2 py-1 " ++ (
              CSVDataError.hasTeamNameError(error) ? "bg-red-200 text-red-800" : ""
            )}>
            {StudentCSVData.teamName(studentData)->Belt.Option.getWithDefault("") |> str}
          </td>
          <td
            className={"border border-gray-400 truncate text-xs px-2 py-1 " ++ (
              CSVDataError.hasTagsError(error) ? "bg-red-200 text-red-800" : ""
            )}>
            {StudentCSVData.tags(studentData)->Belt.Option.getWithDefault("") |> str}
          </td>
          <td
            className={"border border-gray-400 truncate text-xs px-2 py-1 " ++ (
              CSVDataError.hasAffiliationError(error) ? "bg-red-200 text-red-800" : ""
            )}>
            {StudentCSVData.affiliation(studentData)->Belt.Option.getWithDefault("") |> str}
          </td>
        </tr>
      }) |> React.array} </tbody>
  </table>
}

let errorTabulation = (csvData, fileInvalid) => {
  switch fileInvalid {
  | None => React.null
  | Some(fileInvalid) =>
    switch fileInvalid {
    | InvalidData(errors) =>
      <div>
        {errors->Array.length > 10
          ? {
              <div>
                {errorsTable(csvData, Js.Array.slice(~start=0, ~end_=10, errors))}
                <div className="text-red-700 text-sm mt-5">
                  {t("more_errors_text") |> str}
                  <textArea
                    readOnly=true
                    className="border border-gray-400 bg-gray-100 rounded p-1 mt-1 w-full focus:outline-none focus:ring focus:border-primary-400">
                    {Array.map(
                      error => CSVDataError.rowNumber(error),
                      Js.Array2.sliceFrom(errors, 10),
                    )->Js.Array2.joinWith(",") |> str}
                  </textArea>
                </div>
              </div>
            }
          : errorsTable(csvData, errors)}
        <div className="text-red-700 text-sm mt-4 rounded-md bg-red-100 p-3">
          <div className="text-sm font-semibold pb-2"> {t("error_summary_title") |> str} </div>
          <ul className="list-disc list-inside text-xs">
            {errors
            |> Array.map(error => CSVDataError.errors(error))
            |> ArrayUtils.flattenV2
            |> ArrayUtils.distinct
            |> Array.map(error =>
              <li>
                {str(
                  switch error {
                  | CSVDataError.Name => t("csv_data_errors.invalid_name")
                  | Title => t("csv_data_errors.invalid_title")
                  | TeamName => t("csv_data_errors.invalid_team_name")
                  | Email => t("csv_data_errors.invalid_email")
                  | Affiliation => t("csv_data_errors.invalid_affiliation")
                  | Tags => t("csv_data_errors.invalid_tags")
                  },
                )}
              </li>
            )
            |> React.array}
          </ul>
        </div>
      </div>
    | _ => React.null
    }
  }
}

@react.component
let make = (~courseId) => {
  let (state, send) = React.useReducer(reducer, initialState)
  <form onSubmit={submitForm(courseId, send)}>
    <input name="authenticity_token" type_="hidden" value={AuthenticityToken.fromHead()} />
    <div className="mx-auto bg-white">
      <div className="max-w-2xl p-6 mx-auto">
        <h5 className="uppercase text-center border-b border-gray-400 pb-2 mb-4">
          {t("drawer_heading")->str}
        </h5>
        <DisablingCover disabled={state.saving} message="Processing...">
          <div className="mt-5">
            <div className="flex justify-between items-center text-center">
              <div>
                <label className="tracking-wide text-xs font-semibold" htmlFor="csv-file-input">
                  {t("csv_file_input_label")->str}
                </label>
                <HelpIcon
                  className="ml-2"
                  link="https://docs.pupilfirst.com/#/students?id=importing-students-in-bulk">
                  {str(
                    "This file will be used to import students in bulk. Check the sample file for the required format.",
                  )}
                </HelpIcon>
              </div>
              <div
                className="flex items-center text-primary-500 text-xs font-semibold hover:text-primary-700 hover:underline">
                <PfIcon className="if i-download-regular if-fw mr-2" />
                <a href="https://docs.pupilfirst.com/files/student_import_sample.csv">
                  {t("example_csv_link") |> str}
                </a>
              </div>
            </div>
            <CSVReader
              label=""
              inputId="csv-file-input"
              inputName="csv"
              cssClass="hidden"
              parserOptions={CSVReader.parserOptions(~header=true, ~skipEmptyLines="true", ())}
              onFileLoaded={(x, y) => {
                send(LoadCSVData(x, y))
              }}
              onError={_ => send(UpdateFileInvalid(Some(InvalidCSVFile)))}
            />
            <label
              onClick={_event => clearFile(send)}
              className="file-input-label mt-2"
              htmlFor="csv-file-input">
              <i className="fas fa-upload mr-2 text-gray-600 text-lg" />
              <span className="truncate"> {fileInputText(~fileInfo=state.fileInfo)->str} </span>
            </label>
            {ReactUtils.nullIf(
              csvDataTable(state.csvData, state.fileInvalid),
              ArrayUtils.isEmpty(state.csvData),
            )}
            <School__InputGroupError
              message={switch state.fileInvalid {
              | Some(invalidStatus) =>
                switch invalidStatus {
                | InvalidCSVFile => t("csv_file_errors.invalid")
                | EmptyFile => t("csv_file_errors.empty")
                | InvalidTemplate => t("csv_file_errors.invalid_template")
                | ExceededEntries => t("csv_file_errors.exceeded_entries")
                | InvalidData(_) => t("csv_file_errors.invalid_data")
                }
              | None => ""
              }}
              active={state.fileInvalid->Belt.Option.isSome}
            />
            {errorTabulation(state.csvData, state.fileInvalid)}
          </div>
        </DisablingCover>
      </div>
      <div className="max-w-2xl flex justify-end px-6 pb-6 mx-auto">
        <button disabled={saveDisabled(state)} className="w-auto btn btn-success">
          {t("import_button_text")->str}
        </button>
      </div>
    </div>
  </form>
}
