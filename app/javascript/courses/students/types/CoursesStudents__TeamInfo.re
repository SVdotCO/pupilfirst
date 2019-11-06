type student = {
  id: string,
  name: string,
  title: string,
  avatarUrl: option(string),
};

type t = {
  id: string,
  name: string,
  levelId: string,
  students: array(student),
};

let id = t => t.id;
let levelId = t => t.levelId;

let name = t => t.name;

[@dead "title"] let title = t => t.title;

let students = t => t.students;

let studentId = (student: student) => student.id;

let studentName = (student: student) => student.name;

let studentTitle = (student: student) => student.title;

let makeStudent = (~id, ~name, ~title, ~avatarUrl) => {
  id,
  name,
  title,
  avatarUrl,
};

let make = (~id, ~name, ~levelId, ~students) => {
  id,
  name,
  levelId,
  students,
};

let makeFromJS = teamDetails => {
  teamDetails
  |> Js.Array.map(team =>
       switch (team) {
       | Some(team) =>
         let students =
           team##students
           |> Array.map(student =>
                makeStudent(
                  ~id=student##id,
                  ~name=student##name,
                  ~title=student##title,
                  ~avatarUrl=student##avatarUrl,
                )
              );
         [
           make(
             ~id=team##id,
             ~name=team##name,
             ~levelId=team##levelId,
             ~students,
           ),
         ];
       | None => []
       }
     );
};