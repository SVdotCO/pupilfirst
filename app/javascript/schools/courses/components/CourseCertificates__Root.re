open CourseCertificates__Types;

let str = React.string;
let tc = I18n.t(~scope="components.CourseCertificates__Root");
let ts = I18n.t(~scope="shared");

type drawer =
  | NewCertificate
  | EditCertificate(Certificate.t)
  | Closed;

type state = {
  name: string,
  imageFilename: option(string),
  drawer,
  saving: bool,
  certificates: array(Certificate.t),
};

let computeInitialState = certificates => {
  name: "",
  imageFilename: None,
  drawer: Closed,
  saving: false,
  certificates,
};

type action =
  | OpenNewCertificateDrawer
  | OpenEditCertificateDrawer(Certificate.t)
  | UpdateName(string)
  | UpdateImageFilename(string)
  | RemoveFilename
  | CloseDrawer
  | BeginSaving
  | FinishCreating(array(Certificate.t))
  | FailSaving;

let reducer = (state, action) =>
  switch (action) {
  | OpenNewCertificateDrawer => {...state, drawer: NewCertificate}
  | OpenEditCertificateDrawer(certificate) => {
      ...state,
      drawer: EditCertificate(certificate),
    }
  | UpdateName(name) => {...state, name}
  | UpdateImageFilename(filename) => {
      ...state,
      imageFilename: Some(filename),
    }
  | RemoveFilename => {...state, imageFilename: None}
  | CloseDrawer => {...state, drawer: Closed}
  | BeginSaving => {...state, saving: true}
  | FinishCreating(certificates) => {
      ...state,
      saving: false,
      drawer: Closed,
      certificates,
    }
  | FailSaving => {...state, saving: false}
  };

let saveDisabled = state => {
  state.imageFilename == None || state.saving;
};

let submitForm = (course, send, event) => {
  ReactEvent.Form.preventDefault(event);
  send(BeginSaving);

  let formData =
    ReactEvent.Form.target(event)
    ->DomUtils.EventTarget.unsafeToElement
    ->DomUtils.FormData.create;

  let url = "/school/courses/" ++ Course.id(course) ++ "/certificates";

  Api.sendFormData(
    url,
    formData,
    json => {
      Notification.success(
        ts("done_exclamation"),
        tc("success_notification"),
      );

      let certificates =
        json
        |> Json.Decode.(field("certificates", array(Certificate.decode)));

      send(FinishCreating(certificates));
    },
    () => send(FailSaving),
  );
};

let imageInputText = imageFilename =>
  imageFilename->Belt.Option.getWithDefault(
    tc("certificate_base_image_placeholder"),
  );

let selectFile = (send, event) => {
  let files = ReactEvent.Form.target(event)##files;

  // The user can cancel the selection, which will result in files being an empty array.
  if (ArrayUtils.isEmpty(files)) {
    send(RemoveFilename);
  } else {
    let file = Js.Array.unsafe_get(files, 0);
    send(UpdateImageFilename(file##name));
  };
};

let newCertificateDrawer = (course, state, send) =>
  <SchoolAdmin__EditorDrawer
    closeDrawerCB={() => send(CloseDrawer)} closeButtonTitle={ts("cancel")}>
    <form onSubmit={submitForm(course, send)}>
      <input
        name="authenticity_token"
        type_="hidden"
        value={AuthenticityToken.fromHead()}
      />
      <div className="flex flex-col min-h-screen">
        <div className="bg-white flex-grow-0">
          <div className="max-w-2xl px-6 pt-5 mx-auto">
            <h5
              className="uppercase text-center border-b border-gray-400 pb-2">
              {tc("create_action")->str}
            </h5>
          </div>
          <div className="max-w-2xl pt-6 px-6 mx-auto">
            <div className="max-w-2xl pb-6 mx-auto">
              <div className="mt-5">
                <label
                  className="inline-block tracking-wide text-gray-900 text-xs font-semibold"
                  htmlFor="name">
                  {tc("name_label")->str}
                </label>
                <span className="text-xs">
                  {" (" ++ ts("optional") ++ ")" |> str}
                </span>
                <input
                  className="appearance-none block w-full bg-white text-gray-800 border border-gray-400 rounded py-3 px-4 mt-2 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"
                  id="name"
                  type_="text"
                  name="name"
                  placeholder={tc("name_placeholder")}
                  value={state.name}
                  onChange={event =>
                    send(UpdateName(ReactEvent.Form.target(event)##value))
                  }
                />
              </div>
              <div className="mt-5">
                <label
                  className="block tracking-wide text-xs font-semibold"
                  htmlFor="certificate-file-input">
                  {tc("certificate_base_image_label")->str}
                </label>
                <input
                  disabled={state.saving}
                  className="hidden"
                  name="image"
                  type_="file"
                  id="certificate-file-input"
                  required=false
                  multiple=false
                  onChange={selectFile(send)}
                />
                <label
                  className="file-input-label mt-2"
                  htmlFor="certificate-file-input">
                  <i className="fas fa-upload mr-2 text-gray-600 text-lg" />
                  <span className="truncate">
                    {imageInputText(state.imageFilename)->str}
                  </span>
                </label>
              </div>
            </div>
          </div>
        </div>
        <div className="bg-gray-100 flex-grow">
          <div className="max-w-2xl p-6 mx-auto">
            <div
              className="flex max-w-2xl w-full justify-between items-center mx-auto">
              <button
                disabled={saveDisabled(state)}
                className="w-auto btn btn-large btn-primary">
                {tc("create_action")->str}
              </button>
            </div>
          </div>
        </div>
      </div>
    </form>
  </SchoolAdmin__EditorDrawer>;

let editCertificateDrawer = (course, state, send, certificate) => {
  <SchoolAdmin__EditorDrawer
    closeDrawerCB={() => send(CloseDrawer)}
    closeButtonTitle={ts("cancel")}
    size=SchoolAdmin__EditorDrawer.Large>
    <div className="flex flex-col min-h-screen">
      <div className="bg-white flex-grow-0">
        <div className="max-w-4xl px-6 pt-5 mx-auto">
          <h5 className="uppercase text-center border-b border-gray-400 pb-2">
            {tc("edit_action")->str}
          </h5>
        </div>
      </div>
    </div>
  </SchoolAdmin__EditorDrawer>;
};

[@react.component]
let make = (~course, ~certificates) => {
  let (state, send) =
    React.useReducerWithMapState(reducer, certificates, computeInitialState);

  <div className="flex flex-1 h-screen overflow-y-scroll">
    {switch (state.drawer) {
     | NewCertificate => newCertificateDrawer(course, state, send)
     | EditCertificate(certificate) =>
       editCertificateDrawer(course, state, send, certificate)
     | Closed => React.null
     }}
    <div className="flex-1 flex flex-col bg-gray-100">
      <div className="flex px-6 py-2 items-center justify-between">
        <button
          onClick={_ => {send(OpenNewCertificateDrawer)}}
          className="max-w-2xl w-full flex mx-auto items-center justify-center relative bg-white text-primary-500 hover:bg-gray-100 hover:text-primary-600 hover:shadow-lg focus:outline-none border-2 border-gray-400 border-dashed hover:border-primary-300 p-6 rounded-lg mt-8 cursor-pointer">
          <i className="fas fa-plus-circle" />
          <h5 className="font-semibold ml-2"> {tc("create_action")->str} </h5>
        </button>
      </div>
      {state.certificates |> ArrayUtils.isEmpty
         ? <div
             className="flex justify-center bg-gray-100 border rounded p-3 italic mx-auto max-w-2xl w-full">
             {tc("no_certificates")->str}
           </div>
         : <div className="px-6 pb-4 mt-5 flex flex-1 bg-gray-100">
             <div className="max-w-2xl w-full mx-auto relative">
               <h4 className="mt-5 w-full"> {tc("heading")->str} </h4>
               <div className="flex mt-4 -mx-3 items-start flex-wrap">
                 {state.certificates
                  |> ArrayUtils.copyAndSort((x, y) =>
                       DateFns.differenceInSeconds(
                         y |> Certificate.updatedAt,
                         x |> Certificate.updatedAt,
                       )
                     )
                  |> Array.map(certificate =>
                       <div
                         key={Certificate.id(certificate)}
                         ariaLabel={
                           "Certificate " ++ Certificate.id(certificate)
                         }
                         className="flex w-1/2 items-center mb-4 px-3">
                         <div
                           className="course-faculty__list-item shadow bg-white overflow-hidden rounded-lg flex flex-col w-full">
                           <div className="flex flex-1 justify-between">
                             <div className="pt-4 pb-3 px-4">
                               <div className="text-sm">
                                 <p className="text-black font-semibold">
                                   {Certificate.name(certificate)->str}
                                 </p>
                                 <p
                                   className="text-gray-600 font-semibold text-xs mt-px">
                                   {tc(
                                      ~count=
                                        Certificate.issuedCertificates(
                                          certificate,
                                        ),
                                      "issued_count",
                                    )
                                    ->str}
                                 </p>
                               </div>
                               {Certificate.active(certificate)
                                  ? <div
                                      className="flex flex-wrap text-gray-600 font-semibold text-xs mt-1">
                                      <span
                                        className="px-2 py-1 border rounded bg-secondary-100 text-primary-600 mt-1 mr-1">
                                        {tc("active_tag")->str}
                                      </span>
                                    </div>
                                  : React.null}
                             </div>
                             <div className="flex">
                               <a
                                 ariaLabel={
                                   "Edit Certificate "
                                   ++ Certificate.id(certificate)
                                 }
                                 className="w-10 text-sm text-gray-700 hover:text-gray-900 cursor-pointer flex items-center justify-center hover:bg-gray-200"
                                 onClick={_ =>
                                   send(
                                     OpenEditCertificateDrawer(certificate),
                                   )
                                 }>
                                 <i className="fas fa-edit" />
                               </a>
                               {Certificate.issuedCertificates(certificate)
                                == 0
                                  ? <a
                                      ariaLabel={
                                        "Delete Certificate "
                                        ++ Certificate.id(certificate)
                                      }
                                      className="w-10 text-sm text-gray-700 hover:text-gray-900 cursor-pointer flex items-center justify-center hover:bg-gray-200"
                                      href="#">
                                      <i className="fas fa-trash-alt" />
                                    </a>
                                  : React.null}
                             </div>
                           </div>
                         </div>
                       </div>
                     )
                  |> React.array}
               </div>
             </div>
           </div>}
    </div>
  </div>;
};
