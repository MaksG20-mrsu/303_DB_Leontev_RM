<?php
// index.php - веб-приложение для отображения списка студентов с фильтром по группе

$dsn = "sqlite:" . __DIR__ . "/students.db";

try {
    $pdo = new PDO($dsn);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    // Если не удалось соединиться, покажем ошибку и остановим выполнение
    die("<p><strong>Ошибка подключения к базе данных:</strong> " . htmlspecialchars($e->getMessage()) . "</p>");
}

// Получение списка номеров всех действующих групп для выпадающего списка
$currentYear = date("Y");
$groupNumbers = [];  // массив для номеров групп
try {
    $stmt = $pdo->prepare("SELECT `number` FROM `groups` WHERE `graduation_year` <= :year ORDER BY `number`");
    $stmt->execute(['year' => $currentYear]);
    $groupNumbers = $stmt->fetchAll(PDO::FETCH_COLUMN);
} catch (PDOException $e) {
    die("<p>Ошибка запроса групп: " . htmlspecialchars($e->getMessage()) . "</p>");
}
if (!$groupNumbers) {
    $groupNumbers = [];
}
// Преобразуем к строкам (на случай, если номера групп числовые)
$groupNumbers = array_map('strval', $groupNumbers);

// Определяем выбранный фильтр (номер группы) из параметра запроса
$selectedGroup = "";
if (isset($_GET['group'])) {
    $selectedGroup = trim($_GET['group']);
    // Проверка валидности: если не пусто и нет в списке доступных групп, сбрасываем фильтр
    if ($selectedGroup !== "" && !in_array($selectedGroup, $groupNumbers, true)) {
        $selectedGroup = "";
    }
}

// Подготовка SQL-запроса для выборки студентов с учетом фильтра
$sql = "
    SELECT 
        g.number AS group_number,
        g.program AS program,
        s.last_name AS last_name,
        s.first_name AS first_name,
        s.patronymic AS patronymic,
        s.gender AS gender,
        s.birthdate AS birthdate,
        s.student_card AS student_card
    FROM students s
    JOIN groups g ON s.group_id = g.id
    WHERE g.graduation_year <= :year";
if ($selectedGroup !== "") {
    $sql .= " AND g.number = :groupNumber";
}
$sql .= " ORDER BY g.number, s.last_name";

try {
    $stmt = $pdo->prepare($sql);
    if ($selectedGroup === "") {
        $stmt->execute(['year' => $currentYear]);
    } else {
        $stmt->execute(['year' => $currentYear, 'groupNumber' => $selectedGroup]);
    }
    $students = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    die("<p>Ошибка запроса студентов: " . htmlspecialchars($e->getMessage()) . "</p>");
}

// Обработка данных студентов: объединяем ФИО и форматируем дату
foreach ($students as &$st) {
    // Объединяем фамилию, имя, отчество в одну строку
    $fio = $st['last_name'] . " " . $st['first_name'];
    if (!empty($st['patronymic'])) {
        $fio .= " " . $st['patronymic'];
    }
    $st['fio'] = $fio;
    // Форматируем дату рождения в дд.мм.гггг
    if (!empty($st['birthdate'])) {
        $st['birthdate'] = date("d.m.Y", strtotime($st['birthdate']));
    }
}
// Освобождаем ссылку
unset($st);
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Список студентов</title>
    <style>
        table { border-collapse: collapse; }
        th, td { border: 1px solid #000; padding: 4px 8px; }
        th { background: #f0f0f0; }
    </style>
</head>
<body>

<h2>Список студентов<?php
    if ($selectedGroup !== "" && in_array($selectedGroup, $groupNumbers, true)) {
        echo " – группа $selectedGroup";
    } ?></h2>

<form method="get" action="index.php">
    <label for="groupSelect">Выберите группу:</label>
    <select name="group" id="groupSelect">
        <option value=""<?= ($selectedGroup === "" ? " selected" : "") ?>>Все группы</option>
        <?php foreach ($groupNumbers as $groupNum): ?>
            <option value="<?= htmlspecialchars($groupNum) ?>"<?= ($groupNum === $selectedGroup ? " selected" : "") ?>>
                <?= htmlspecialchars($groupNum) ?>
            </option>
        <?php endforeach; ?>
    </select>
    <button type="submit">Показать</button>
</form>

<?php if (empty($students)): ?>
    <p><em>Нет данных для отображения.</em></p>
<?php else: ?>
    <table>
        <thead>
        <tr>
            <th>номер группы</th>
            <th>направление подготовки</th>
            <th>ФИО</th>
            <th>пол</th>
            <th>дата рождения</th>
            <th>номер студенческого билета</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($students as $st): ?>
            <tr>
                <td><?= htmlspecialchars($st['group_number']) ?></td>
                <td><?= htmlspecialchars($st['program']) ?></td>
                <td><?= htmlspecialchars($st['fio']) ?></td>
                <td><?= htmlspecialchars($st['gender']) ?></td>
                <td><?= htmlspecialchars($st['birthdate']) ?></td>
                <td><?= htmlspecialchars($st['student_card']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
<?php endif; ?>

</body>
</html>
