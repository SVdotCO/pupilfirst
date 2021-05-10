type audioRecorderControls = {
  url: option<string>,
  recording: bool,
  startRecording: unit => unit,
  stopRecording: unit => unit,
  id: option<string>,
}
let str = React.string
@bs.module("./CoursesCurriculum__AudioNavigator")
external audioRecorder: (string, bool => unit) => audioRecorderControls = "audioRecorder"

@react.component
let make = (~attachingCB, ~attachFileCB) => {
  let audioRecorder = audioRecorder(AuthenticityToken.fromHead(), attachingCB)
  React.useEffect1(() => {
    switch audioRecorder.id {
    | Some(id) => attachFileCB(id, "recorderaudio")
    | None => ()
    }
    None
  }, [audioRecorder.id])
  <>
    {audioRecorder.recording
      ? <div className="flex flex-col md:flex-row pointer-cursor pt-2 md:items-center">
          <button
            className="flex items-center bg-gray-200 border rounded-full hover:bg-gray-300"
            onClick={_e => audioRecorder.stopRecording()}>
            <div
              className="flex flex-shrink-0 items-center justify-center bg-red-600 shadow-md rounded-full h-10 w-10">
              <Icon className="if i-stop-solid text-base text-white relative z-10" />
              <span
                className="w-8 h-8 z-0 animate-ping absolute inline-flex rounded-full bg-red-600 opacity-75"
              />
            </div>
            <span className="inline-block pl-3 pr-4 text-xs font-semibold">
              {str("Recording...")}
            </span>
          </button>
        </div>
      : <div className="flex flex-col md:flex-row pointer-cursor pt-2 md:items-center">
          <button
            className="flex items-center bg-red-100 border rounded-full hover:bg-red-200"
            onClick={_e => audioRecorder.startRecording()}>
            <div
              className="flex flex-shrink-0 items-center justify-center bg-white shadow-md rounded-full h-10 w-10">
              <Icon className="if i-microphone-fill-light text-lg text-red-600" />
            </div>
            <span className="inline-block pl-3 pr-4 text-xs font-semibold">
              {str({
                switch audioRecorder.id {
                | Some(id) => "Record Again"
                | None => "Start Recording"
                }
              })}
            </span>
          </button>
          {switch audioRecorder.id {
          | None => React.null
          | Some(id) =>
            <audio
              src={"/timeline_event_files/" ++ id ++ "/download"}
              controls=true
              className="pt-3 md:pt-0 md:pl-4"
            />
          }}
        </div>}
  </>
}
