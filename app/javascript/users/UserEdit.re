[%bs.raw {|require("./UserEdit.css")|}];

let str = React.string;

type state = {
  name: string,
  about: string,
  avatarUrl: option(string),
  currentPassword: string,
  newPassword: string,
  confirmPassword: string,
  dailyDigest: bool,
  passwordForAccountDeletion: string,
  showDeleteAccountForm: bool,
  deletingAccount: bool,
  saving: bool,
};

type action =
  | UpdateName(string)
  | UpdateAbout(string)
  | UpdateCurrentPassword(string)
  | UpdateNewPassword(string)
  | UpdateNewPassWordConfirm(string)
  | UpdatePasswordForDeletion(string)
  | UpdateDailyDigest(bool)
  | ChangeDeleteAccountFormVisibility(bool)
  | StartSaving
  | FinishSaving
  | StartDeletingAccount
  | FinishAccountDeletion;

let reducer = (state, action) => {
  switch (action) {
  | UpdateName(name) => {...state, name}
  | UpdateAbout(about) => {...state, about}
  | UpdateCurrentPassword(currentPassword) => {...state, currentPassword}
  | UpdateNewPassword(newPassword) => {...state, newPassword}
  | UpdateNewPassWordConfirm(confirmPassword) => {...state, confirmPassword}
  | UpdatePasswordForDeletion(passwordForAccountDeletion) => {
      ...state,
      passwordForAccountDeletion,
    }
  | UpdateDailyDigest(dailyDigest) => {...state, dailyDigest}
  | StartSaving => {...state, saving: true}
  | ChangeDeleteAccountFormVisibility(showDeleteAccountForm) => {
      ...state,
      showDeleteAccountForm,
      passwordForAccountDeletion: "",
    }
  | FinishSaving => {...state, saving: false}
  | StartDeletingAccount => {...state, deletingAccount: true}
  | FinishAccountDeletion => {
      ...state,
      showDeleteAccountForm: false,
      deletingAccount: false,
      passwordForAccountDeletion: "",
    }
  };
};

module UpdateUserQuery = [%graphql
  {|
   mutation UpdateUserMutation($id: ID!, $name: String!, $about: String, $currentPassword: String, $newPassword: String, $confirmPassword: String, $dailyDigest: Boolean! ) {
     updateUser(id: $id, name: $name, about: $about, currentPassword: $currentPassword, newPassword: $newPassword, confirmNewPassword: $confirmPassword, dailyDigest: $dailyDigest  ) {
        success
       }
     }
   |}
];

module InitiateAccountDeletionQuery = [%graphql
  {|
   mutation InitiateAccountDeletionMutation($id: ID!, $password: String! ) {
     initiateAccountDeletion(id: $id, password: $password ) {
        success
       }
     }
   |}
];

let updateUser = (state, send, id, event) => {
  ReactEvent.Mouse.preventDefault(event);
  send(StartSaving);

  UpdateUserQuery.make(
    ~id,
    ~name=state.name,
    ~about=state.about,
    ~currentPassword=state.currentPassword,
    ~newPassword=state.newPassword,
    ~confirmPassword=state.confirmPassword,
    ~dailyDigest=state.dailyDigest,
    (),
  )
  |> GraphqlQuery.sendQuery
  |> Js.Promise.then_(result => {
       result##updateUser##success
         ? {
           send(FinishSaving);
         }
         : send(FinishSaving);
       Js.Promise.resolve();
     })
  |> Js.Promise.catch(_ => {
       send(FinishSaving);
       Js.Promise.resolve();
     })
  |> ignore;
  ();
};

let initiateAccountDeletion = (state, send, id, event) => {
  ReactEvent.Mouse.preventDefault(event);
  send(StartDeletingAccount);

  InitiateAccountDeletionQuery.make(
    ~id,
    ~password=state.passwordForAccountDeletion,
    (),
  )
  |> GraphqlQuery.sendQuery
  |> Js.Promise.then_(result => {
       result##initiateAccountDeletion##success
         ? {
           send(FinishAccountDeletion);
         }
         : send(FinishAccountDeletion);
       Js.Promise.resolve();
     })
  |> Js.Promise.catch(_ => {
       send(FinishAccountDeletion);
       Js.Promise.resolve();
     })
  |> ignore;
  ();
};

[@react.component]
let make = (~currentUserId, ~name, ~about, ~avatarUrl, ~dailyDigest) => {
  let initialState = {
    name,
    about,
    avatarUrl,
    dailyDigest,
    saving: false,
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
    passwordForAccountDeletion: "",
    showDeleteAccountForm: false,
    deletingAccount: false,
  };

  let (state, send) = React.useReducer(reducer, initialState);
  <div className="container mx-auto px-3 py-8 max-w-5xl">
    {state.showDeleteAccountForm
       ? <div
           className="fixed bottom-0 inset-x-0 px-4 pb-4 sm:inset-0 sm:flex sm:items-center sm:justify-center">
           <div className="fixed inset-0">
             <div className="absolute inset-0 bg-gray-800 opacity-75" />
           </div>
           <div
             className="relative z-50 bg-white rounded-lg px-4 pt-5 pb-4 overflow-hidden shadow-xl sm:max-w-lg sm:w-full sm:p-6"
             role="dialog"
             ariaModal=true
             ariaLabelledby="modal-headline">
             <div className="hidden sm:block absolute top-0 right-0 pt-4 pr-4">
               <button
                 onClick={_ =>
                   send(ChangeDeleteAccountFormVisibility(false))
                 }
                 type_="button"
                 className="text-gray-400 hover:text-gray-500 focus:outline-none"
                 ariaLabel="Close">
                 <svg
                   className="h-6 w-6"
                   stroke="currentColor"
                   fill="none"
                   viewBox="0 0 24 24">
                   <path
                     strokeLinecap="round"
                     strokeLinejoin="round"
                     strokeWidth="2"
                     d="M6 18L18 6M6 6l12 12"
                   />
                 </svg>
               </button>
             </div>
             <div className="sm:flex sm:items-start">
               <div
                 className="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-200 sm:mx-0 sm:h-10 sm:w-10">
                 <svg
                   className="h-6 w-6 text-red-600"
                   stroke="currentColor"
                   fill="none"
                   viewBox="0 0 24 24">
                   <path
                     strokeLinecap="round"
                     strokeLinejoin="round"
                     strokeWidth="2"
                     d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                   />
                 </svg>
               </div>
               <div className="mt-3 sm:mt-0 sm:ml-4">
                 <h3
                   className="text-lg text-center sm:text-left font-semibold"
                   id="modal-headline">
                   {"Delete account" |> str}
                 </h3>
                 <div className="mt-2">
                   <p
                     className="text-sm text-center sm:text-left text-gray-700">
                     {"Are you sure you want to deactivate your account? All of your data will be permanently removed from our servers forever. This action cannot be undone."
                      |> str}
                   </p>
                 </div>
                 <div className="mt-3">
                   <label
                     htmlFor="confirm_password"
                     className="block text-sm font-semibold">
                     {"Password" |> str}
                   </label>
                   <input
                     type_="password"
                     value={state.passwordForAccountDeletion}
                     onChange={event =>
                       send(
                         UpdatePasswordForDeletion(
                           ReactEvent.Form.target(event)##value,
                         ),
                       )
                     }
                     id="confirm_password"
                     className="appearance-none block text-sm w-full shadow-sm border border-gray-400 rounded px-4 py-2 my-2 leading-relaxed focus:outline-none focus:border-gray-500"
                     placeholder="Type your password"
                   />
                 </div>
               </div>
             </div>
             <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
               <span
                 className="flex w-full rounded-md shadow-sm sm:ml-3 sm:w-auto">
                 <button
                   onClick={initiateAccountDeletion(
                     state,
                     send,
                     currentUserId,
                   )}
                   type_="button"
                   className="inline-flex justify-center w-full rounded-md border border-transparent px-4 py-2 bg-red-600 text-sm font-semibold text-white shadow-sm hover:bg-red-700 focus:outline-none">
                   {"Confirm Deletion" |> str}
                 </button>
               </span>
               <span
                 className="mt-3 flex w-full rounded-md shadow-sm sm:mt-0 sm:w-auto">
                 <button
                   onClick={_ =>
                     send(ChangeDeleteAccountFormVisibility(false))
                   }
                   type_="button"
                   className="inline-flex justify-center w-full rounded-md border border-gray-300 px-4 py-2 bg-white text-sm font-semibold text-gray-700 hover:bg-gray-100 hover:text-gray-600 focus:outline-none">
                   {"Cancel" |> str}
                 </button>
               </span>
             </div>
           </div>
         </div>
       : React.null}
    <div className="bg-white shadow sm:rounded-lg">
      <div className="px-4 py-5 sm:p-6">
        <div className="flex flex-col md:flex-row">
          <div className="w-full md:w-1/3 pr-4">
            <h3 className="text-lg font-semibold">
              {"Edit your profile" |> str}
            </h3>
            <p className="mt-1 text-sm text-gray-700">
              {"This information will be displayed publicly so be careful what you share."
               |> str}
            </p>
          </div>
          <div className="mt-5 md:mt-0 w-full md:w-2/3">
            <div className="">
              <div className="">
                <label
                  htmlFor="user_name" className="block text-sm font-semibold">
                  {"Name" |> str}
                </label>
              </div>
            </div>
            <input
              id="user_name"
              value={state.name}
              onChange={event =>
                send(UpdateName(ReactEvent.Form.target(event)##value))
              }
              className="appearance-none mb-2 block text-sm w-full shadow-sm border border-gray-400 rounded px-4 py-2 my-2 leading-relaxed focus:outline-none focus:border-gray-500"
              placeholder="Type your name"
            />
            <School__InputGroupError
              message="Not a valid name"
              active={state.name |> String.trim |> String.length < 2}
            />
            <div className="mt-6">
              <label htmlFor="about" className="block text-sm font-semibold">
                {"About" |> str}
              </label>
              <div>
                <textarea
                  id="about"
                  value={state.about}
                  rows=3
                  onChange={event =>
                    send(UpdateAbout(ReactEvent.Form.target(event)##value))
                  }
                  className="appearance-none block text-sm w-full shadow-sm border border-gray-400 rounded px-4 py-2 my-2 leading-relaxed focus:outline-none focus:border-gray-500"
                  placeholder="A brief introduction about yourself"
                />
              </div>
            </div>
            <div className="mt-6">
              <form>
                <input
                  name="authenticity_token"
                  type_="hidden"
                  value={AuthenticityToken.fromHead()}
                />
                <label className="block text-sm font-semibold">
                  {"Photo" |> str}
                </label>
                <div className="mt-2 flex items-center">
                  <span
                    className="inline-block h-14 w-14 rounded-full overflow-hidden bg-gray-200 border-2 boder-gray-400">
                    {switch (avatarUrl) {
                     | Some(url) => <img src=url />
                     | None => <Avatar name />
                     }}
                  </span>
                  <span className="ml-5 rounded-md shadow-sm">
                    <label
                      htmlFor="user-edit__avatar-input"
                      className="py-2 px-3 border border-gray-400 rounded-md text-sm font-semibold hover:text-gray-800 focus:outline-none active:bg-gray-100 active:text-gray-800">
                      {"Change photo" |> str}
                    </label>
                    <input
                      className="hidden"
                      name="avatar"
                      type_="file"
                      id="user-edit__avatar-input"
                      required=false
                      multiple=false
                    />
                  </span>
                </div>
              </form>
            </div>
          </div>
        </div>
        <div className="flex flex-col md:flex-row mt-10 md:mt-12">
          <div className="w-full md:w-1/3 pr-4">
            <h3 className="text-lg font-semibold"> {"Security" |> str} </h3>
            <p className="mt-1 text-sm text-gray-700">
              {"Update your login credentials for the school." |> str}
            </p>
          </div>
          <div className="mt-5 md:mt-0 w-full md:w-2/3">
            <p className="font-semibold">
              {"Change your current password" |> str}
            </p>
            <div className="mt-6">
              <label
                htmlFor="current_password"
                className="block text-sm font-semibold">
                {"Current Password" |> str}
              </label>
              <input
                value={state.currentPassword}
                type_="password"
                autoComplete="off"
                onChange={event =>
                  send(
                    UpdateCurrentPassword(
                      ReactEvent.Form.target(event)##value,
                    ),
                  )
                }
                id="current_password"
                className="appearance-none block text-sm w-full shadow-sm border border-gray-400 rounded px-4 py-2 my-2 leading-relaxed focus:outline-none focus:border-gray-500"
                placeholder="Type current password"
              />
            </div>
            <div className="mt-6">
              <label
                htmlFor="new_password" className="block text-sm font-semibold">
                {"New Password" |> str}
              </label>
              <input
                autoComplete="off"
                type_="password"
                id="new_password"
                value={state.newPassword}
                onChange={event =>
                  send(
                    UpdateNewPassword(ReactEvent.Form.target(event)##value),
                  )
                }
                className="appearance-none block text-sm w-full shadow-sm border border-gray-400 rounded px-4 py-2 my-2 leading-relaxed focus:outline-none focus:border-gray-500"
                placeholder="Type new password"
              />
            </div>
            <div className="mt-6">
              <label
                autoComplete="off"
                htmlFor="confirm_password"
                className="block text-sm font-semibold">
                {"Confirm password" |> str}
              </label>
              <input
                autoComplete="off"
                type_="password"
                id="confirm_password"
                value={state.confirmPassword}
                onChange={event =>
                  send(
                    UpdateNewPassWordConfirm(
                      ReactEvent.Form.target(event)##value,
                    ),
                  )
                }
                className="appearance-none block text-sm w-full shadow-sm border border-gray-400 rounded px-4 py-2 my-2 leading-relaxed focus:outline-none focus:border-gray-500"
                placeholder="Confirm new password"
              />
            </div>
          </div>
        </div>
        <div className="flex flex-col md:flex-row mt-10 md:mt-12">
          <div className="w-full md:w-1/3 pr-4">
            <h3 className="text-lg font-semibold">
              {"Notifications" |> str}
            </h3>
            <p className="mt-1 text-sm text-gray-700">
              {"Update settings for email notifications." |> str}
            </p>
          </div>
          <div className="mt-5 md:mt-0 w-full md:w-2/3">
            <p className="font-semibold"> {"Community Digest" |> str} </p>
            <p className="text-sm text-gray-700">
              {"Community digest emails contain new questions from your communities, and a selection of unanswered questions from the past week."
               |> str}
            </p>
            <div className="mt-6">
              <div className="flex items-center">
                <Radio
                  id="daily_mail_enable"
                  label="Send me a daily email"
                  onChange={event =>
                    send(
                      UpdateDailyDigest(
                        ReactEvent.Form.target(event)##checked,
                      ),
                    )
                  }
                  checked={state.dailyDigest}
                />
              </div>
              <div className="mt-4 flex items-center">
                <Radio
                  id="daily_mail_disable"
                  label="Disable"
                  onChange={event =>
                    send(
                      UpdateDailyDigest(
                        !ReactEvent.Form.target(event)##checked,
                      ),
                    )
                  }
                  checked={!state.dailyDigest}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div
        className="bg-gray-100 px-4 py-5 sm:p-6 flex rounded-b-lg justify-end">
        <button
          onClick={updateUser(state, send, currentUserId)}
          className="btn btn-primary">
          {"Save Changes" |> str}
        </button>
      </div>
    </div>
    <div className="bg-white shadow sm:rounded-lg mt-10">
      <div className="px-4 py-5 sm:p-6">
        <div className="flex flex-col md:flex-row">
          <div className="w-full md:w-1/3 pr-4">
            <h3 className="text-lg font-semibold"> {"Account" |> str} </h3>
            <p className="mt-1 text-sm text-gray-700">
              {"Nunc id massa ultricies, hendrerit nibh ac, consequat nisl."
               |> str}
            </p>
          </div>
          <div className="mt-5 md:mt-0 w-full md:w-2/3">
            <p className="font-semibold text-red-700">
              {"Delete account" |> str}
            </p>
            <p className="text-sm text-gray-700 mt-1">
              {"Duis consectetur aliquam justo vitae sodales. Mauris vitae lectus id tellus blandit luctus et non leo. Nunc id massa ultricies, hendrerit nibh ac, consequat nisl."
               |> str}
            </p>
            <div className="mt-4">
              <button
                onClick={_ => send(ChangeDeleteAccountFormVisibility(true))}
                className="py-2 px-3 border border-red-500 text-red-600 rounded text-xs font-semibold hover:bg-red-600 hover:text-white focus:outline-none active:bg-red-700 active:text-white">
                {"Delete your account" |> str}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>;
};
