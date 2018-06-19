/// See `SQLQuery`.
public typealias PostgreSQLBinaryOperator = GenericSQLBinaryOperator

/// See `SQLQuery`.
public typealias PostgreSQLColumnConstraintAlgorithm = GenericSQLColumnConstraintAlgorithm<
    PostgreSQLExpression, PostgreSQLCollation, PostgreSQLPrimaryKey, PostgreSQLForeignKey
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
public typealias PostgreSQLConflictResolution = GenericSQLConflictResolution

/// See `SQLQuery`
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
    PostgreSQLTableIdentifier, PostgreSQLIdentifier, PostgreSQLConflictResolution
>

/// See `SQLQuery`.
public typealias PostgreSQLGroupBy = GenericSQLGroupBy<PostgreSQLExpression>

/// See `SQLQuery`.
public typealias PostgreSQLIdentifier = GenericSQLIdentifier

/// See `SQLQuery`.
public typealias PostgreSQLInsert = GenericSQLInsert<
    PostgreSQLTableIdentifier, PostgreSQLColumnIdentifier, PostgreSQLExpression
>

/// See `SQLQuery`.
public typealias PostgreSQLJoin = GenericSQLJoin<
    PostgreSQLJoinMethod, PostgreSQLTableIdentifier, PostgreSQLExpression
>

/// See `SQLQuery`.
public typealias PostgreSQLJoinMethod = GenericSQLJoinMethod

/// See `SQLQuery`.
public typealias PostgreSQLLiteral = GenericSQLLiteral<PostgreSQLDefaultLiteral>

/// See `SQLQuery`.
public typealias PostgreSQLOrderBy = GenericSQLOrderBy<PostgreSQLExpression, PostgreSQLDirection>

/// See `SQLQuery`.
public typealias PostgreSQLSelect = GenericSQLSelect<
    PostgreSQLDistinct, PostgreSQLSelectExpression, PostgreSQLTableIdentifier, PostgreSQLJoin, PostgreSQLExpression, PostgreSQLGroupBy, PostgreSQLOrderBy
>

/// See `SQLQuery`.
public typealias PostgreSQLSelectExpression = GenericSQLSelectExpression<PostgreSQLExpression, PostgreSQLIdentifier>

/// See `SQLQuery`.
public typealias PostgreSQLTableConstraintAlgorithm = GenericSQLTableConstraintAlgorithm<
    PostgreSQLIdentifier, PostgreSQLExpression, PostgreSQLCollation, PostgreSQLPrimaryKey, PostgreSQLForeignKey
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
