type props = {
  authenticityToken: string,
  customizations: SchoolCustomize__Customizations.t,
  schoolName: string,
  schoolAbout: option<string>,
}

let decodeProps = json => {
  open Json.Decode
  {
    authenticityToken: json |> field("authenticityToken", string),
    customizations: json |> field("customizations", SchoolCustomize__Customizations.decode),
    schoolName: json |> field("schoolName", string),
    schoolAbout: json |> field("schoolAbout", optional(string)),
  }
}

let props = DomUtils.parseJSONTag(~id="school-customize-data", ()) |> decodeProps

switch ReactDOM.querySelector("#school-customize") {
| Some(element) =>
  ReactDOM.render(
    <SchoolCustomize__Root
      authenticityToken=props.authenticityToken
      customizations=props.customizations
      schoolName=props.schoolName
      schoolAbout=props.schoolAbout
    />,
    element,
  )
| None => ()
}
