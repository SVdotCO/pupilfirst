type t = {
  id: string,
  name: string,
  number: int,
  teamsInLevel: int,
};

let id = t => t.id;
let name = t => t.name;

let number = t => t.number;

let teamsInLevel = t => t.teamsInLevel;

let decode = json =>
  Json.Decode.{
    id: json |> field("id", string),
    name: json |> field("name", string),
    number: json |> field("number", int),
    teamsInLevel: json |> field("teamsInLevel", int),
  };

let sort = levels =>
  levels |> ArrayUtils.copyAndSort((x, y) => x.number - y.number);

[@dead "unsafeLevelNumber"] let unsafeLevelNumber = (levels, componentName, levelId) =>
  "Level "
  ++ (
    levels
    |> ArrayUtils.unsafeFind(
         l => l.id == levelId,
         "Unable to find level with id: "
         ++ levelId
         ++ "in CoursesStudents__"
         ++ componentName,
       )
    |> number
    |> string_of_int
  );