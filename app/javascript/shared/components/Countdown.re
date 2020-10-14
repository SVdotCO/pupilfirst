let str = React.string;

type state = {
  seconds: int,
  timeoutId: option(Js.Global.timeoutId),
  reload: bool,
};

type action =
  | SetTimeout(Js.Global.timeoutId)
  | Decrement
  | ToggleRelaod;

let reducer = (state, action) =>
  switch (action) {
  | ToggleRelaod => {...state, reload: !state.reload}
  | SetTimeout(timeoutId) => {...state, timeoutId: Some(timeoutId)}
  | Decrement => {...state, seconds: state.seconds - 1, reload: !state.reload}
  };

let percentage = (current, total) => {
  int_of_float(float_of_int(current) /. float_of_int(total) *. 100.00);
};

let relaodTimer = (timeoutCB, state, send, ()) => {
  state.timeoutId->Belt.Option.forEach(Js.Global.clearTimeout);
  state.seconds == 0 ? timeoutCB() : send(Decrement);
};

let reload = (timeoutCB, state, send, ()) => {
  let timeoutId =
    Js.Global.setTimeout(
      relaodTimer(timeoutCB, state, send),
      state.timeoutId->Belt.Option.mapWithDefault(0, _ => 1000),
    );
  send(SetTimeout(timeoutId));
  None;
};

[@react.component]
let make = (~seconds, ~timeoutCB) => {
  let (state, send) =
    React.useReducer(reducer, {seconds, timeoutId: None, reload: false});
  React.useEffect1(reload(timeoutCB, state, send), [|state.reload|]);
  <div>
    <DoughnutChart
      percentage={percentage(state.seconds, seconds)}
      className="mx-auto"
      text={string_of_int(state.seconds)}
      pulse={state.seconds == 0}
    />
  </div>;
};
