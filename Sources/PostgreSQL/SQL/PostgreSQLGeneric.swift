/// See `SQLQuery`.
public typealias PostgreSQLColumnConstraintAlgorithm = GenericSQLColumnConstraintAlgorithm<
    PostgreSQLExpression, PostgreSQLCollation, PostgreSQLPrimaryKeyDefault, PostgreSQLForeignKey
>

/// See `SQLQuery`.
public typealias PostgreSQLColumnConstraint = GenericSQLColumnConstraint<
    PostgreSQLIdentifier, PostgreSQLColumnConstraintAlgorithm
>

/// See `SQLQuery`.
public typealias PostgreSQLColumnDefinition = GenericSQLColumnDefinition<
    PostgreSQLColumnIdentifier, PostgreSQLDataType, PostgreSQLColumnConstraint
>

/// See `SQLQuery`.
public typealias PostgreSQLColumnIdentifier = GenericSQLColumnIdentifier<
    PostgreSQLTableIdentifier, PostgreSQLIdentifier
>

/// See `SQLQuery`.
public typealias PostgreSQLCreateIndex = GenericSQLCreateIndex<
    PostgreSQLIndexModifier, PostgreSQLIdentifier, PostgreSQLColumnIdentifier
>

/// See `SQLQuery`.
public typealias PostgreSQLCreateTable = GenericSQLCreateTable<
    PostgreSQLTableIdentifier, PostgreSQLColumnDefinition, PostgreSQLTableConstraint
>

/// See `SQLQuery`.
public typealias PostgreSQLDelete = GenericSQLDelete<
    PostgreSQLTableIdentifier, PostgreSQLExpression
>

/// See `SQLQuery`.
public typealias PostgreSQLDirection = GenericSQLDirection

/// See `SQLQuery`.
public typealias PostgreSQLDistinct = GenericSQLDistinct

/// See `SQLQuery`.
public typealias PostgreSQLDropTable = GenericSQLDropTable<PostgreSQLTableIdentifier>

/// See `SQLQuery`.
public typealias PostgreSQLExpression = GenericSQLExpression<
    PostgreSQLLiteral, PostgreSQLBind, PostgreSQLColumnIdentifier, PostgreSQLBinaryOperator, PostgreSQLFunction, PostgreSQLQuery
>

/// See `SQLQuery`.
public typealias PostgreSQLForeignKey = GenericSQLForeignKey<
    PostgreSQLTableIdentifier, PostgreSQLIdentifier, PostgreSQLForeignKeyAction
>

/// See `SQLQuery`.
public typealias PostgreSQLForeignKeyAction = GenericSQLForeignKeyAction

/// See `SQLQuery`.
public typealias PostgreSQLGroupBy = GenericSQLGroupBy<PostgreSQLExpression>

/// See `SQLQuery`.
public typealias PostgreSQLIndexModifier = GenericSQLIndexModifier

/// See `SQLQuery`.
public typealias PostgreSQLIdentifier = GenericSQLIdentifier

/// See `SQLQuery`.
public typealias PostgreSQLJoin = GenericSQLJoin<
    PostgreSQLJoinMethod, PostgreSQLTableIdentifier, PostgreSQLExpression
>

/// See `SQLQuery`.
public typealias PostgreSQLJoinMethod = GenericSQLJoinMethod

/// See `SQLQuery`.
public typealias PostgreSQLLiteral = GenericSQLLiteral<PostgreSQLDefaultLiteral, PostgreSQLBoolLiteral>

/// See `SQLQuery`.
public typealias PostgreSQLOrderBy = GenericSQLOrderBy<PostgreSQLExpression, PostgreSQLDirection>

/// See `SQLQuery`.
public typealias PostgreSQLSelect = GenericSQLSelect<
    PostgreSQLDistinct, PostgreSQLSelectExpression, PostgreSQLTableIdentifier, PostgreSQLJoin, PostgreSQLExpression, PostgreSQLGroupBy, PostgreSQLOrderBy
>

/// See `SQLQuery`.
public typealias PostgreSQLSelectExpression = GenericSQLSelectExpression<PostgreSQLExpression, PostgreSQLIdentifier, PostgreSQLTableIdentifier>

/// See `SQLQuery`.
public typealias PostgreSQLTableConstraintAlgorithm = GenericSQLTableConstraintAlgorithm<
    PostgreSQLIdentifier, PostgreSQLExpression, PostgreSQLCollation, PostgreSQLForeignKey
>

/// See `SQLQuery`.
public typealias PostgreSQLTableConstraint = GenericSQLTableConstraint<
    PostgreSQLIdentifier, PostgreSQLTableConstraintAlgorithm
>

/// See `SQLQuery`.
public typealias PostgreSQLTableIdentifier = GenericSQLTableIdentifier<PostgreSQLIdentifier>

/// See `SQLQuery`.
public typealias PostgreSQLUpdate = GenericSQLUpdate<
    PostgreSQLTableIdentifier, PostgreSQLIdentifier, PostgreSQLExpression
>
